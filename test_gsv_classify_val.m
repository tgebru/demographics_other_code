% Test fine-grained classification on validation data, using validation detections

options=set_options();
options.gpu_num=2; %use GPU 2
% Load validation GT
val_gt_data = load('/home/jkrause/gsv_classify/gsv_val.mat');

% Load validation detections
val_dpm_data = load('/home/jkrause/gsv_classify/val_dpm_results.mat');

images = val_gt_data.images;
image_preds = repmat(struct('bboxes', [], 'preds', [],'im_fname',[]), 1, numel(images));
for i = 1:numel(images)
  image_preds(i).bboxes = val_dpm_data.image_preds(i).bboxes;
  image_preds(i).im_fname=val_gt_data.images(i).im_fname;
end

% Subsample
% TODO: Remove
%{
rand('seed', 0);
num_ims_to_run = 1000;
perm = randperm(numel(images));
images = images(perm(1:num_ims_to_run));
image_preds = image_preds(perm(1:num_ims_to_run));
%}

BATCH_SIZE=options.batch_size;
options.skip_augmentation=false;
if ~exists(options.save_fname)
  if options.skip_augmentation
    fprintf('Skipping augmentation...\n');
    options.resize_dims = [options.cropped_dim, options.cropped_dim];

    fprintf('Get rid of images without bboxes..\n');
    im_inds=1:numel(image_preds);
    im_inds_w_bboxes=im_inds(arrayfun(@(x)~isempty(x.bboxes),...
       image_preds));
    
    images_w_bboxes=image_preds(im_inds_w_bboxes);
    im_nums_w_bboxes=arrayfun(@(x,y)repmat(y,size(x.bboxes,1),1),...
        images_w_bboxes,im_inds_w_bboxes,'uniformoutput',false);
    im_nums_w_bboxes=vertcat(im_nums_w_bboxes{:});
    
    fprintf('Image names for each bboxs..\n')
    images_w_bboxes_names={image_preds(im_nums_w_bboxes).im_fname};
    images_w_bboxes_names=cellfun(@(x)fullfile(options.data_dir, x),...
         images_w_bboxes_names,'uniformoutput',false);

    %All predicted bboxes
    pred_bboxes_cell = arrayfun(@(x)x.bboxes, images_w_bboxes,...
       'uniformoutput', false);
    num_pred_bboxes = sum(arrayfun(@(x)size(x.bboxes, 1),...
      images_w_bboxes));
    pred_bboxes = zeros(num_pred_bboxes, 6);
    pred_bboxes = vertcat(pred_bboxes_cell{:});

    %Experiment with different batch sizes
    batch_sizes=[1 10 20 50 100 200 400 800];
    avg_times=zeros(batch_sizes,1);
    %for b=1:length(batch_sizes) 
      %option.batch_size=batch_sizes(b);
      BATCH_SIZE=options.batch_size;
    %{ 
      if(b==1)
        find_str='input_dim: 200'
      else
        find_str=sprintf('input_dim: %d',batch_sizes(b-1));
      end
      repl_str=sprintf('input_dim: %d',batch_sizes(b));
      cmd=sprintf('sed -i ''s/%s/%s/'' %s > out',find_str,...
            repl_str,options.model_def_file);
      status = unix(cmd);
    %} 
      num_batches=length(1:BATCH_SIZE:num_pred_bboxes);
      cur_batch=0;
      %NUM_BATCHES=20;
      ftime=zeros(num_batches,1);
      preptime=zeros(num_batches,1);
      all_times=zeros(num_batches,1);

      %Class predictions
      bbox_preds=zeros(num_pred_bboxes,2);
      
      fprintf('testing batch size %d\n',BATCH_SIZE);
      for i=1:BATCH_SIZE:num_pred_bboxes
        tic
        cur_batch = cur_batch + 1;

        fprintf('Batch %d/%d\n',cur_batch,num_batches);
        end_indx=min(i+BATCH_SIZE-1,num_pred_bboxes);

        %Concatenate images for each bbox
        %ims=cellfun(@(x)imread(x),...
        %    unique(images_w_bboxes_names(i:end_indx),'stable'),...
        %      'uniformoutput',false);
        
        %Load images
        unique_ims_in_batch=unique(images_w_bboxes_names(i:end_indx));
        num_unique_in_batch=numel(unique_ims_in_batch);
        ims=cell(num_unique_in_batch,1);
        parfor imloop=1:num_unique_in_batch
          ims{imloop}=imread(unique_ims_in_batch{imloop});
        end
          
        im_nums_in_batch=hist(im_nums_w_bboxes(i:end_indx),...
            length(unique(im_nums_w_bboxes(i:end_indx))));
        ims=cellfun(@(x,y)repmat({x},y,size({x})),ims,...
            num2cell(im_nums_in_batch'),'uniformoutput',false);
        ims=vertcat(ims{:});

        %Pad to make batch sizes equal
        if (end_indx-i ~=BATCH_SIZE-1) 
          num_ims_to_pad=BATCH_SIZE-(end_indx-i)-1;
          ims=vertcat(ims{:},repmat({single(zeros(size(ims{1})))},...
              num_ims_to_pad,1));
          bb_pad=[1 1 2 2];
          pred_bb_padded=[pred_bboxes(i:end_indx,1:4);repmat(bb_pad,num_ims_to_pad,1)];

          %Classify with Caffe
          [preptime(cur_batch),ftime(cur_batch),bpreds]=classify_bboxes_batch...
              (ims,pred_bb_padded,options);
          bbox_preds(i:end_indx,:)=bpreds(1:end_indx-i+1,:);
        else
          %Classify with Caffe
          [preptime(cur_batch),ftime(cur_batch),bbox_preds(i:end_indx,:)]=...
              classify_bboxes_batch(ims,pred_bboxes(i:end_indx,1:4),...
                options);
        end
        all_times(cur_batch)=toc;
        fprintf('%g per forward prop for batchsize=%d \n',ftime(cur_batch)/BATCH_SIZE,BATCH_SIZE);
        fprintf('%g per bbox for batchsize=%d \n',all_times(cur_batch)/BATCH_SIZE,BATCH_SIZE);
      %end
      %avg_times(b)=avg_time;
    end
    avg_time=mean(ftime(2:end))/BATCH_SIZE;
    all_time=mean(all_times(2:end-1))/BATCH_SIZE;
    fprintf('avg total time: %g per image for batchsize=%d \n',all_time,BATCH_SIZE);
    fprintf('avg fowardprop time: %g per image for batchsize=%d \n',avg_time,BATCH_SIZE);
    fprintf('Best batch =%d\n',batch_sizes(find(avg_times==min(avg_times))));

  else
    options.use_full=true;   
    options.use_center=false;
    for i = 1:numel(images)
      fprintf('Image %d/%d\n', i, numel(images));
      im_fname = fullfile(options.data_dir, images(i).im_fname);
      if isempty(image_preds(i).bboxes)
        continue;
      end
      bboxes = image_preds(i).bboxes(:, 1:4);
      im = imread(im_fname);
      image_preds(i).preds = classify_bboxes_full(im, bboxes, options);
    end
  end
  % TODO: save results
  options.save_fname='val_all_bboxes.mat'
  %save(options.save_fname, 'images', 'image_preds');
  save(options.save_fname,'images', 'pred_bboxes','bbox_preds','im_nums_w_bboxes','options');
end


% TODO: Figure out evaluation.........
% make sure big enough is handled like in validation
% report fg AP as well as accuracy(?)
% also report detection ap
%[ap, acc, num_fg_eval] = gsv_eval(images, image_preds, options)
[ap, acc, num_fg_eval] = gsv_eval_tim(images, pred_bboxes,bbox_preds,im_nums_w_bboxes,options)
