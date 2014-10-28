%options.threshold=-1.2;
%options.set_threshold=true;

load_data=0;
save_fname='./val_data.mat'

%%% only for testing
if ~load_data
  options=set_options();
  options.gpu_num=2;
  options.evalac=1;

  
  val_gt_data = load('/home/jkrause/gsv_classify/gsv_val.mat');
  val_dpm_data = load('/scail/scratch/u/jkrause/gsv_classify/dpm_test/13105_1_8_0_val_locprior.mat');
  images = val_gt_data.images;
  image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));

  for i = 1:numel(images)
    image_preds(i).bboxes = val_dpm_data.image_preds(i).bboxes;
    image_preds(i).im_fname=val_gt_data.images(i).im_fname;
  end

  %CDF of boundingbox 
  bboxes=vertcat(image_preds(:).bboxes);
  thresholds=bboxes(:,6);   
  [f,x]=ecdf(thresholds);

  %TODO: remove this only for testing
  num_ims_to_run = numel(images); 
  images = images(1:num_ims_to_run);
  image_preds = image_preds(1:num_ims_to_run);
  gsv_classify_all(images,image_preds,save_fname,options);
else
  ims=load(save_fname);
  images=ims.images;
  image_preds=ims.image_preds;
  options=set_options();
  %options=ims.options;
  [ap, acc, num_fg_eval]=gsv_eval(images, image_preds, options)
end
