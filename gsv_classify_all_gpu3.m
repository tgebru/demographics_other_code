clear all;
%matlabpool(12);
detected_bboxes_root='/home/jkrause/gsv_data/city_results_merged_cal/';
detected_ims_root='/imagenetdb2/data/geo/gsv_city_done_unwarp/';
detected_files=dir(detected_bboxes_root);
save_dir_root='/imagenetdb2/data/geo/gsv_city_done_cnn/';

%Go through cities by alphabetical order
num_files=numel(detected_files);
cities=cell(num_files-2,1);
for i=3:num_files
    cities{i-2}=detected_files(i).name;
end
num_cities=numel(cities);

options=set_options();
options.gpu_num=3;
options.evalac=0;

%Only run on the first half of cities
for c=2: 2 %floor(num_cities*0.5)
  tic;
  fprintf('GPU 3 working on city %d out of %d\n',c,num_cities);
  %DPM predictions
  detected_bboxes_file=sprintf('%s%s',detected_bboxes_root,cities{c});
  %Image files
  detected_ims_file=sprintf('%s%s',detected_ims_root,cities{c});

  image_preds=load(detected_bboxes_file);
  image_preds=image_preds.image_preds;

  images=load(detected_ims_file);
  images=images.images;

  num_pred_ims=numel(image_preds);
  assert(num_pred_ims == numel(images));
  [image_preds(:).im_fname]=images.im_fname;
  image_preds(1).preds=[];
    
  save_fname=[save_dir_root cities{c}(1:end-4) '_fg.mat'];


  %{
  val_gt_data = load('/home/jkrause/gsv_classify/gsv_val.mat');
  val_dpm_data = load('/home/jkrause/gsv_classify/val_dpm_results.mat');
  images = val_gt_data.images;
  image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));
  for i = 1:numel(images)
    image_preds(i).bboxes = val_dpm_data.image_preds(i).bboxes;
    image_preds(i).im_fname=val_gt_data.images(i).im_fname;
  end
  
  num_ims_to_run = numel(images);
  images = images(1:num_ims_to_run);
  image_preds = image_preds(1:num_ims_to_run);
  %}
  gsv_classify_all(images,image_preds,save_fname,options);
  toc
end

