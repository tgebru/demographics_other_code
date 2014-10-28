clear all;

% Run cnn on gt bboxes
options = [];
options.det_thresh = -1;
options.resize_dims = [256, 256];
options.model_def_file = '/home/jkrause/caffe/caffe/examples/cars/big_train_deploy.prototxt';
%options.model_file = '/home/jkrause/caffe/caffe/examples/cars/caffe_car_big_train_iter_228000';
%options.model_file = '/home/jkrause/caffe/caffe/examples/cars/caffe_car_big_train_blur_iter_112000';
options.model_file = '/home/jkrause/caffe/caffe/examples/cars/caffe_car_big_train_blur_iter_130000';
options.mean_fname = '/data/jkrause/cropped_resized/car_big_mean.mat';
options.use_gpu = true;
options.image_dim = 256;
options.cropped_dim = 227;
options.num_classes = 2657;
options.data_dir = '/data/jkrause/gsv_100k_unwarp';
options.source_prior_fname = 'source_prior.mat';
options.target_prior_fname = 'target_prior.mat';
options.prior_reweight = true;


im_data = load('gsv_gt_bboxes.mat');

load('im_ids_100.txt');
im_ids = im_ids_100;
gt_ids = [im_data.images.imageid];
[~, inds] = ismember(im_ids, gt_ids);
images = im_data.images(inds);

%rand('seed', 0);
%num_ims_to_run = 1000;
%perm = randperm(numel(im_data.images));
%images = im_data.images(perm(1:num_ims_to_run));


% Pretend that we detected the GT bboxes
image_preds = repmat(struct('bboxes', [], 'preds', []), 1, numel(images));
for i = 1:numel(images)
  fprintf('Image %d/%d\n', i, numel(images));
  bboxes = images(i).bboxes;
  good_mask = logical(images(i).big_enough) & logical(images(i).classes ~= -1);
  bboxes = horzcat(bboxes(good_mask, :), ones(nnz(good_mask), 1));
  if ~isempty(bboxes)
    im_fname = fullfile(options.data_dir, images(i).im_fname);
    im = imread(im_fname);
    preds = classify_bboxes(im, bboxes, options);
    image_preds(i).bboxes = bboxes;
    image_preds(i).preds = preds;
  end
end
[ap, acc, num_fg_eval] = gsv_eval(images, image_preds);
acc
num_fg_eval
