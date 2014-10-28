% Fine grain classification on gsv data
function gsv_classify_all(images,image_preds,save_fname,options);

addpath('/scail/scratch/u/jkrause/gsv_classify/unwarp_cluster/unwarp')

BATCH_SIZE=options.batch_size;
CROPPED_DIM=options.cropped_dim;
if options.skip_augmentation
  fprintf('Skipping augmentation...\n');

  fprintf('Get rid of images without bboxes..\n');
  im_inds=1:numel(image_preds);
  im_inds_w_bboxes=im_inds(arrayfun(@(x)~isempty(x.bboxes),...
     image_preds));
  
  images_w_bboxes=image_preds(im_inds_w_bboxes);
  im_nums_w_bboxes=arrayfun(@(x,y)repmat(y,size(x.bboxes,1),1),...
      images_w_bboxes,im_inds_w_bboxes,'uniformoutput',false);
  im_nums_w_bboxes=vertcat(im_nums_w_bboxes{:});
  
  fprintf('Image names for each bbox...\n')
  images_w_bboxes_names={image_preds(im_nums_w_bboxes).im_fname};

  %All predicted bboxes
  fprintf('Getting predicted bounding boxes...\n')
  pred_bboxes_cell = arrayfun(@(x)x.bboxes, images_w_bboxes,...
     'uniformoutput', false);
  pred_bboxes = vertcat(pred_bboxes_cell{:});
  
  %Remove bounding boxes with low scores
  if options.set_threshold
    keep_mask=pred_bboxes(:,6)>=options.threshold;
    pred_bboxes=pred_bboxes(keep_mask,:);
    %im_nums_w_bboxes=im_nums_w_bboxes(keep_mask);
    images_w_bboxes_names=images_w_bboxes_names(keep_mask);
  end

  num_pred_bboxes=size(pred_bboxes,1);

  BATCH_SIZE=options.batch_size;
  num_batches=length(1:BATCH_SIZE:num_pred_bboxes);
  cur_batch=0;
  ftime=zeros(num_batches,1);
  preptime=zeros(num_batches,1);
  readtime=zeros(num_batches,1);
  all_times=zeros(num_batches,1);

  %Class predictions
  bbox_preds=zeros(num_pred_bboxes,2*options.num_preds_to_save);
  
  fprintf('testing batch size %d\n',BATCH_SIZE);

  for i=1:BATCH_SIZE:num_pred_bboxes
    s=tic;
    cur_batch = cur_batch + 1;

    fprintf('Batch %d/%d\n',cur_batch,num_batches);
    end_indx=min(i+BATCH_SIZE-1,num_pred_bboxes);

    %Load images
    rdt=tic;

    [unique_ims_in_batch,inds,allinds]=unique(images_w_bboxes_names(i:end_indx),'stable');
    im_nums_in_batch=[diff(inds);end_indx-inds(end)+1];
    num_unique_in_batch=numel(unique_ims_in_batch);
    ims=cell(num_unique_in_batch,1);

    parfor imloop=1:num_unique_in_batch
      try
        ims{imloop}=imread(unique_ims_in_batch{imloop});
      catch
        fprintf('unwarping %s\n',unique_ims_in_batch{imloop});
        unwarp(unique_ims_in_batch{imloop}); 
        ims{imloop}=imread(strrep(unique_ims_in_batch{imloop},'data','tgebru'));
      end
      ims{imloop}=put_in_caffe_form(ims{imloop});
    end

    %%%%%%% Only comment during testing %%%%
    %ims=cellfun(@(x)imread({x}),{images_w_bboxes_names{i:end_indx}}...,
    %'uniformoutput',false);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Replicate images
    ims=cellfun(@(x,y)repmat({x},y,size({x})),ims,...
        num2cell(im_nums_in_batch),'uniformoutput',false);
    ims=vertcat(ims{:});

    readtime(cur_batch)=toc(rdt);


    if (end_indx-i ~=BATCH_SIZE-1) 
      [preptime(cur_batch),ftime(cur_batch),bpreds]=classify_bboxes_batch...
          (ims,round(pred_bboxes(i:end_indx,1:4)),options);
      bbox_preds(i:end_indx,:)=bpreds(1:end_indx-i+1,:);
   
    else
      %Classify with Caffe
        [preptime(cur_batch),ftime(cur_batch),bbox_preds(i:end_indx,:)]=...
          classify_bboxes_batch(ims,round(pred_bboxes(i:end_indx,1:4)),...
              options);
    end

    all_times(cur_batch)=toc(s);
    fprintf('%g imread time per bbox for batchsize=%d \n',readtime(cur_batch)/BATCH_SIZE,BATCH_SIZE);
    fprintf('%g prep time per bbox for batchsize=%d \n',preptime(cur_batch)/BATCH_SIZE,BATCH_SIZE);
    fprintf('%g per forward prop for batchsize=%d \n',ftime(cur_batch)/BATCH_SIZE,BATCH_SIZE);
    fprintf('%g total per bbox for batchsize=%d \n',all_times(cur_batch)/BATCH_SIZE,BATCH_SIZE);
  end
  avg_time=mean(ftime(1:end))/BATCH_SIZE;
  all_time=mean(all_times(1:end))/BATCH_SIZE;
  all_read_time=mean(readtime(1:end))/BATCH_SIZE;
  fprintf('avg total time: %g per image for batchsize=%d \n',all_time,BATCH_SIZE);
  fprintf('avg read time: %g per image for batchsize=%d \n',all_read_time,BATCH_SIZE);
  fprintf('avg fowardprop time: %g per image for batchsize=%d \n',avg_time,BATCH_SIZE);

else
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

%Save results
%Aggregate the bboxes for saving
tic;
fprintf('Aggregatting bboxes for saving\n');
b=1;
if ~options.set_threshold
   keep_mask=ones(length(im_nums_w_bboxes),1);
end
for i=1:length(im_nums_w_bboxes)
  if(keep_mask(i)==1)
    image_preds(im_nums_w_bboxes(i)).preds=... 
    [image_preds(im_nums_w_bboxes(i)).preds;bbox_preds(b,:)];
    b=b+1;
  else
    image_preds(im_nums_w_bboxes(i)).preds=... 
    [image_preds(im_nums_w_bboxes(i)).preds;...
    -1*ones(1,2*options.num_preds_to_save)];
  end
end
save(save_fname, 'images', 'image_preds','avg_time','all_time','all_read_time','options','-v7.3');

save_t=toc;
fprintf('Took %g to save\n',save_t);

%Evaluation
if (options.evalac)
  [ap, acc, num_fg_eval] = gsv_eval(images, image_preds, options)
  %[ap1, acc1, num_fg_eval1] = gsv_eval_tim(images, pred_bboxes,bbox_preds,im_nums_w_bboxes,options)
end

function unwarp(im_name)
  unwarped_name=strrep(im_name,'gsv_unwarp','gsv');
  unwarped = unwarp_ims({imread(unwarped_name)});
  cropped = crop(unwarped);
  new_im_name=strrep(im_name,'data','tgebru');
  if ~exist(new_im_name)
    [pathstr,name,ext] = fileparts(new_im_name);
    mkdir(pathstr);
  end
  imwrite(cropped{1}, new_im_name);
  
