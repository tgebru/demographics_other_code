options=set_options();
options.gpu_num=2;
options.evalac=0;
options.data_dir = '/data/jkrause/gsv_100k_unwarp';

data_root='.';
val_gt_data = load(fullfile(data_root,'gsv_val.mat'));
val_dpm_data = load(fullfile(data_root,'val_dpm_results.mat'));
images = val_gt_data.images;
image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));

for i = 1:numel(images)
  image_preds(i).bboxes = val_gt_data.images(i).bboxes;
  image_preds(i).big_enough = val_gt_data.images(i).big_enough;
  val_gt_data.images(i).im_fname=fullfile(options.data_dir,val_gt_data.images(i).im_fname);
  image_preds(i).im_fname=val_gt_data.images(i).im_fname;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%TODO: remove this only for testing
%num_ims_to_run = 100;
%images = images(1:num_ims_to_run);
%image_preds = image_preds(1:num_ims_to_run);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save_fname='val_gsv_gt_bboxes.mat';

if ~exist(save_fname)
  gsv_classify_all(images,image_preds,save_fname,options);
else
  d=load(save_fname)
  options.test_all=false;
  options.test_make=false;
  options.test_submodel=false;
  options.test_price=false;
  options.test_foreign=false;
  options.test_country=false;
  options.test_model=false;
  options.visualize_results=false;
  [ap, acc, num_fg_eval] = gsv_eval(d.images,d.image_preds,options)
end

