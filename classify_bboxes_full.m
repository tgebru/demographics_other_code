function preds = classify_bboxes_full(im, bboxes, options)
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
  caffe('set_device', 3);
else
  caffe('set_mode_cpu');
end


persistent prior_mult;
if isempty(prior_mult) && options.use_class_prior
  fprintf('Load priors\n');
  source_data = load(options.source_prior_fname);
  target_data = load(options.target_prior_fname);
  prior_mult = (1 - options.prior_strength * ones(size(target_data.probs))) + ...
    options.prior_strength * (target_data.probs ./ source_data.probs);
  prior_mult = prior_mult(:);
  loaded_priors = true;
end

% put into test mode
caffe('set_phase_test');

preds = zeros(num_bboxes, 2);

for i = 1:num_bboxes
  fprintf('bbox %d\n', i);

  input_data = {get_regions(im, bboxes(i,:), options)};

  % do forward pass to get scores
  scores = caffe('forward', input_data);

  % TODO: Check if averaging by multiplying is better...
  % average output scores
  scores = reshape(scores{1}, options.num_classes, []);
  scores = mean(scores, 2);
  if options.use_class_prior
    scores = scores .* prior_mult;
  end
  [max_score, max_ind] = max(scores);
  preds(i,:) = [max_ind - 1, max_score]; %0-indexed
end
end


function images = get_regions(im, bbox, options)
  % TODO: Sample neighborhood/simulate that it's a detection
  num_bboxes = 1;
  bbox_ind = 1;
  sampled_bboxes = zeros(num_bboxes, 4);

  % Get sampled bboxes
  sampled_bboxes(bbox_ind, :) = bbox;
  bbox_ind = bbox_ind + 1;

  % Get bbox regions
  regions = cell(num_bboxes, 1);
  for i = 1:num_bboxes
    bbox = round(sampled_bboxes(i,:));
    % x1 y1 x2 y2
    x1 = bbox(1);
    y1 = bbox(2);
    x2 = bbox(3);
    y2 = bbox(4);
    regions{i} = single(imresize(im(y1:y2, x1:x2,:), options.resize_dims, ...
      'bilinear', 'antialiasing', false));
  end

  % Put in caffe format
  num_ims = num_bboxes * (1 * options.use_center + 4 * options.use_corners + options.use_full) * (1 + options.use_flips);

  persistent IMAGE_MEAN;
  if isempty(IMAGE_MEAN)
    d = load(options.mean_fname);
    IMAGE_MEAN = d.image_mean;
  end
  IMAGE_DIM = options.image_dim;
  CROPPED_DIM = options.cropped_dim;
  images = zeros(CROPPED_DIM, CROPPED_DIM, 3, num_ims, 'single');

  curr = 1;
  RESIZE_DIMS = options.resize_dims;
  IMAGE_MEAN_RESIZED= imresize(IMAGE_MEAN, RESIZE_DIMS, ...
    'bilinear', 'antialiasing', false);

  for k = 1:numel(regions)
    % permute from RGB to BGR (IMAGE_MEAN is already BGR)
    im = regions{k}(:,:,[3 2 1]) - IMAGE_MEAN_RESIZED;

    % oversample (4 corners, center, and their x-axis flips)
    indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
    if options.use_corners
      for i = indices
        for j = indices
          images(:, :, :, curr) = ...
              permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
          curr = curr + 1;
        end
      end
    end
    if options.use_center
      center = floor(indices(2) / 2)+1;
      images(:,:,:,curr) = ...
          permute(im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:), ...
              [2 1 3]);
      curr = curr + 1;
    end
    if options.use_full
      % TODO TODO TODO TODO
      % TODO TODO TODO TODO
      % TODO TODO TODO TODO
      % TODO TODO TODO TODO
      % I'm testing nearest right now!!
      % TODO TODO TODO TODO
      images(:,:,:,curr) = permute(imresize(im, [CROPPED_DIM, CROPPED_DIM], 'nearest', 'antialiasing', false), [2,1,3]);
      curr = curr + 1;
    end
  end
  if options.use_flips
    assert(curr == num_ims/2+1);
    images(:, :, :, curr:end) = images(end:-1:1, :, :, 1:(curr-1));
  end
end
