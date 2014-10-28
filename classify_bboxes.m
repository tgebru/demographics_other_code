function preds = classify_bboxes(im, bboxes, options)
% Column 1 of preds is the actual predictions
% Column 2 is the probability

num_bboxes = size(bboxes, 1);

% init caffe network (spews logging info)
if caffe('is_initialized') == 0
  fprintf('initialize caffe\n');
  caffe('init', options.model_def_file, options.model_file);
  fprintf('initialized\n');
end

% set to use GPU or CPU
if options.use_gpu
  caffe('set_mode_gpu');
else
  caffe('set_mode_cpu');
end


persistent prior_mult;
if isempty(prior_mult) && options.prior_reweight
  fprintf('Load priors\n');
  source_data = load(options.source_prior_fname);
  target_data = load(options.target_prior_fname);
  prior_mult = target_data.probs ./ source_data.probs;
  prior_mult = prior_mult(:);
  loaded_priors = true;
end

% put into test mode
caffe('set_phase_test');

preds = zeros(num_bboxes, 2);

% TODO: Just make something that runs for now. Optimize later!
for i = 1:num_bboxes
  fprintf('bbox %d\n', i);
  regions = extract_regions(im, bboxes(i,:), options.resize_dims);
  region = regions{1};

  % prepare oversampled input
  tic
  input_data = {prepare_image(region, options)};
  toc

  % do forward pass to get scores
  scores = caffe('forward', input_data);

  % average output scores
  scores = reshape(scores{1}, options.num_classes, []);
  scores = mean(scores, 2);
  if options.prior_reweight
    scores = scores .* prior_mult;
  end
  [max_score, max_ind] = max(scores);
  preds(i,:) = [max_ind - 1, max_score]; %0-indexed
end

  % you can also get network weights by calling
  %layers = caffe('get_weights');

% ------------------------------------------------------------------------
function images = prepare_image(im, options)
% ------------------------------------------------------------------------
d = load(options.mean_fname);
IMAGE_MEAN = d.image_mean;
IMAGE_DIM = options.image_dim;
CROPPED_DIM = options.cropped_dim;

% resize to fixed input size
im = single(im);
im = imresize(im, [IMAGE_DIM IMAGE_DIM], 'bilinear');
% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im = im(:,:,[3 2 1]) - IMAGE_MEAN;

% oversample (4 corners, center, and their x-axis flips)
images = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
curr = 1;
for i = indices
  for j = indices
    images(:, :, :, curr) = ...
        permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
    images(:, :, :, curr+5) = images(end:-1:1, :, :, curr);
    curr = curr + 1;
  end
end
center = floor(indices(2) / 2)+1;
images(:,:,:,5) = ...
    permute(im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:), ...
        [2 1 3]);
images(:,:,:,10) = images(end:-1:1, :, :, curr);
