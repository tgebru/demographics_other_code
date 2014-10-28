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

model_data = load(options.dpm_fname);
model = model_data.model;

fnames = textscan(fopen('example_ims.txt', 'r'), '%s');
fnames = fnames{1};
for i = 1:numel(fnames)
  im_fname = fullfile(options.data_dir, fnames{i});
  im = imread(im_fname);
  [bboxes, preds] = gsv_classify(im, model, options);
  vis_preds(im, bboxes, preds);
end
