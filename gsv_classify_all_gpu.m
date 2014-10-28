function gsv_classify_all_gpu(gpu_num,city_queue,chunk_num)

options=set_options();
options.gpu_num=gpu_num;
options.evalac=0;

cur_city=0;
num_cities=numel(city_queue)
broken_dir='/home/tgebru/geo/broken'

%Only run on the first half of cities
while(true)
  tic;
  if isempty(city_queue);
     break;
  end
  c=city_queue{end};
  fprintf('%s\n',c);

  if (~currently_working(c,options) & ~done_working(c,options) )
      cur_city=cur_city+1;
      working=[]; 
      save(fullfile(options.working_dir,c),'working');
      fprintf('GPU %d working on city %d out of %d in chunk %d\n',gpu_num,cur_city,num_cities,chunk_num);

      %DPM predictions
      detected_bboxes_file=fullfile(options.detected_bboxes_root,c);

      %Image files
      detected_ims_file=fullfile(options.detected_ims_root,c);

      image_preds=load(detected_bboxes_file);
      image_preds=image_preds.image_preds;

      images=load(detected_ims_file);
      images=images.images;

      num_pred_ims=numel(image_preds);
      assert(num_pred_ims == numel(images));
      ind=length('/imagenetdb2/data/geo/gsv/');
      num_ims=numel(images);
      fprintf('Changing im names to warped dir...\n');
      for i=1:num_ims
        image_preds(i).im_fname=fullfile(options.data_dir,images(i).im_fname(ind:end));
        image_preds(i).preds=[];
      end

      %image_names=cellfun(@(x)fullfile(options.data_dir, x),...
      %   {images.im_fname(ind:end),'uniformoutput',false);
      %[image_preds(:).im_fname]=[image_names(:)]; %images.im_fname;
      %image_preds(1).preds=[];
        
      save_fname=fullfile(options.save_dir_root,c);
     
      %%% only for testing
      %val_gt_data = load('/home/jkrause/gsv_classify/gsv_val.mat');
      %val_dpm_data = load('/home/jkrause/gsv_classify/val_dpm_results.mat');
      %images = val_gt_data.images;
      %image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));
      %for i = 1:numel(images)
      %  image_preds(i).bboxes = val_dpm_data.image_preds(i).bboxes;
      %  image_preds(i).im_fname=val_gt_data.images(i).im_fname;
      %end
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      %TODO: remove this only for testing
      %num_ims_to_run = 100;
      %images = images(1:num_ims_to_run);
      %image_preds = image_preds(1:num_ims_to_run);
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      gsv_classify_all(images,image_preds,save_fname,options);

      %delete folder cause no longer working
      delete(fullfile(options.working_dir,c));
      toc
    %else
    %  city_queue=vertcat({c},city_queue); %add c to beginning of queue
    
   
  end
  city_queue(end)=[]; %remove from queue
end
