function preds = classify_bboxes(regions, options)

num_regions = numel(regions);

% init caffe network (spews logging info)
if caffe('is_initialized') == 0
  % TODO
%  model_def_file = '../../examples/imagenet/imagenet_deploy.prototxt';
%  model_file = '../../examples/imagenet/caffe_reference_imagenet_model';
  caffe('init', options.model_def_file, options.model_file);
end

% set to use GPU or CPU
if options.use_gpu
  caffe('set_mode_gpu');
else
  caffe('set_mode_cpu');
end

% put into test mode
caffe('set_phase_test');

% prepare oversampled input
tic;
input_data = {prepare_image(im)};
toc;

% do forward pass to get scores
tic;
scores = caffe('forward', input_data);
toc;

% average output scores
scores = reshape(scores{1}, [1000 10]);
scores = mean(scores, 2);

% you can also get network weights by calling
layers = caffe('get_weights');

% ------------------------------------------------------------------------
function images = prepare_image(im)
% ------------------------------------------------------------------------
d = load('ilsvrc_2012_mean');
IMAGE_MEAN = d.image_mean;
IMAGE_DIM = 256;
CROPPED_DIM = 227;

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
