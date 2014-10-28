function options=set_options()
options = [];

%File dirs
options.detected_bboxes_root='/home/jkrause/gsv_data/city_results_merged_cal/';
options.broken_dir_root='/home/tgebru/geo/broken/'
options.warped_cities_root='/imagenetdb2/data/geo/gsv_city_done_unwarp/';
options.detected_ims_root='/home/jkrause/gsv_data/city_files'
%options.save_dir_root='/home/tgebru/geo/gsv_city_done_cnn/';
options.save_dir_root='/home/tgebru/geo/new_gsv_city_done_cnn/';
options.working_dir='/home/tgebru/gsv_city_working/';
options.model_file = '/home/jkrause/caffe/caffe/examples/gsv/caffe_webgsv_iter_222000';
options.mean_fname = '/home/jkrause/caffe/caffe/examples/gsv/webgsv_mean.mat';
options.data_dir='/imagenetdb2/data/geo/gsv_unwarp/';
options.model_def_file = 'fg_deploy.prototxt';
%options.data_dir = '/data/jkrause/gsv_100k_unwarp/';

options.resize_dims = [256, 256];
options.bbox_min_dim = 50;
options.use_gpu = true;
options.batch_size=500;
options.image_dim = 256;
options.cropped_dim = 227;
options.num_classes = 2657;
options.num_preds_to_save =options.num_classes; %20;
options.threshold= -2.3;
options.set_threshold= false;

% TODO: Why isn't the class prior helping??? Is it wrong? It helped by 5 acc before
options.bbox_min_dim = 50;
options.use_class_prior = false;
options.prior_strength = .5; % [0,1]
options.source_prior_fname = 'source_prior.mat';
options.target_prior_fname = 'target_prior.mat';

% TODO: Code better subsampling
% The following with respect to each sampled bbox
options.use_center = true; options.use_corners = false;
options.use_flips = false;
options.sample_neighborhood = false;
options.add_padding=false;
options.skip_augmentation=true;
