options=set_options();
options.gpu_num=2;
options.evalac=1;
options.data_dir = '/data/jkrause/gsv_100k_unwarp';

val_gt_data = load('/home/jkrause/gsv_classify/gsv_val.mat');
val_dpm_data = load('/home/jkrause/gsv_classify/val_dpm_results.mat');
images = val_gt_data.images;
image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));

for i = 1:numel(images)
  image_preds(i).bboxes = val_dpm_data.image_preds(i).bboxes;
  val_gt_data.images(i).im_fname=fullfile(options.data_dir,val_gt_data.images(i).im_fname);
  image_preds(i).im_fname=val_gt_data.images(i).im_fname;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO: remove this only for testing
%num_ims_to_run = 100;
%images = images(1:num_ims_to_run);
%image_preds = image_preds(1:num_ims_to_run);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

options.visualize_results=false;
save_fname='val_gsv_all_bboxes.mat';
if ~exist(save_fname)
  gsv_classify_all(images,image_preds,save_fname,options);
else
  load(save_fname)
  [ap, acc, num_fg_eval] = gsv_eval(images,image_preds,options)
end

