addpath(genpath('/home/jkrause/'))
%model_data = load('/scail/scratch/u/jkrause/gsv_classify/voc-release5/VOC2007/car_final.mat');
%data_dir = '/imagenetdb2/data/geo/gsv_100k_unwarp';
%im = imread('/data/jkrause/gsv_100k_unwarp/im_37.668819_-122.111763_180.000000_0.000000.jpg');


options = [];
options.det_thresh = -1;
options.resize_dims = [256, 256];
%options.model_def_file = '/home/jkrause/caffe/caffe/examples/imagenet/imagenet_deploy.prototxt';
%options.model_file = '/home/jkrause/caffe/caffe/examples/imagenet/caffe_reference_imagenet_model';
%options.mean_fname = '/home/jkrause/caffe/caffe/matlab/caffe/ilsvrc_2012_mean.mat';
options.model_def_file = '/home/jkrause/caffe/caffe/examples/cars/big_train_deploy.prototxt';
options.model_file = '/home/jkrause/caffe/caffe/examples/cars/caffe_car_big_train_iter_228000';
options.mean_fname = '/data/jkrause/cropped_resized/car_big_mean.mat';
options.use_gpu = true;
options.image_dim = 256;
options.cropped_dim = 227;
options.num_classes = 2657;
options.dpm_fname = fullfile(pwd, 'voc-release5/VOC2007/car_final.mat');
options.data_dir = '/data/jkrause/gsv_100k_unwarp';
options.source_prior_fname = 'source_prior.mat';
options.target_prior_fname = 'target_prior.mat';
options.prior_reweight = true;

model_data = load(options.dpm_fname);
model = model_data.model;

im_data = load('gsv_gt_bboxes.mat');

load('im_ids_100.txt');
im_ids = im_ids_100;
gt_ids = [im_data.images.imageid];
[~, inds] = ismember(im_ids, gt_ids);
images = im_data.images(inds);
save_stem = 'timnit_100';

%% TODO
%rand('seed', 0);
%num_ims_to_run = 100;
%save_stem = num2str(num_ims_to_run);
%perm = randperm(numel(im_data.images));
%images = im_data.images(perm(1:num_ims_to_run));


image_preds = repmat(struct('bboxes', [], 'preds', []), 1, numel(images));

save_fname = sprintf('results_%s.mat', save_stem);
%{
if exist(save_fname, 'file')
  fprintf('Loading results from file.\n');
  load(save_fname);
else
%}
  for i = 1:1 %numel(images)
    fprintf('Image %d/%d\n', i, numel(images));
    im_fname = fullfile(options.data_dir, images(i).im_fname);
    im = imread(im_fname);
    [bboxes, preds] = gsv_classify(im, model, options);
    image_preds(i).bboxes = bboxes;
    image_preds(i).preds = preds;
    %vis_preds(im, bboxes, preds);
    keyboard;
  end
  save(save_fname, 'images', 'image_preds');
%end
[ap, acc, num_fg_eval] = gsv_eval(images, image_preds)
