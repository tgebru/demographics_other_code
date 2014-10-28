function [pe,el,preds]=classify_bboxes_batch(ims,bboxes,options);

num_bboxes = size(bboxes, 1);

% init caffe network (spews logging info)
%Initialize caffe only if its not initialized
if (caffe('is_initialized') == 0)
  fprintf('initialize caffe\n');
  caffe('init', options.model_def_file, options.model_file);
  fprintf('initialized\n');

  % set to use GPU or CPU
  if options.use_gpu
    caffe('set_mode_gpu');
    caffe('set_device', options.gpu_num);
  else
    caffe('set_mode_cpu');
  end

  % put into test mode
  caffe('set_phase_test');
end

persistent prior_mult;
if isempty(prior_mult) && options.use_class_prior
  fprintf('Load priors\n');
  source_data = load(options.source_prior_fname);
  target_data = load(options.target_prior_fname);
  prior_mult = (1 - options.prior_strength * ones(size(target_data.probs))) + ...
    options.prior_strength * (target_data.probs ./ source_data.probs);
  prior_mult = prior_mult(:);
  loaded_priors = true;
end

persistent CROPPED_DIM;
persistent RESIZE_DIMS;
persistent IMAGE_MEAN;
persistent IMAGE_MEAN_RESIZED;

if isempty(CROPPED_DIM)
  CROPPED_DIM = options.cropped_dim;
end

if isempty(RESIZE_DIMS)
  RESIZE_DIMS = options.resize_dims;
end

if isempty(IMAGE_MEAN)
  d = load(options.mean_fname);
  IMAGE_MEAN = d.image_mean;

  %if we're skipping all augmentations rize mean to croped dims
  IMAGE_MEAN_RESIZED= permute(imresize(IMAGE_MEAN, [CROPPED_DIM,CROPPED_DIM], ...
      'bilinear', 'antialiasing', false),[2,1,3]);
end

preds = zeros(num_bboxes, 2);
input_data = zeros(CROPPED_DIM,CROPPED_DIM, 3, options.batch_size, 'single');

%Resize images and subtract mean
p=tic;
for i=1:num_bboxes
  x1 = bboxes(i,1);
  y1 = bboxes(i,2);
  x2 = bboxes(i,3);
  y2 = bboxes(i,4);
  im=ims{i};

  input_data(:,:,:,i) = single(imresize(im(x1:x2,y1:y2,:),...
     [CROPPED_DIM, CROPPED_DIM], 'nearest', 'antialiasing', false))-IMAGE_MEAN_RESIZED;

  %%%%%%%%% Only uncomment for testing %%%%
  %im=single(imresize(im(y1:y2,x1:x2,:),RESIZE_DIMS,'nearest',...
  %   'antialiasing',false))-IMAGE_MEAN;

  %input_data(:,:,:,i)=permute(single(imresize(im,[CROPPED_DIM,CROPPED_DIM],...
  %   'antialiasing',false)),[2 1 3]);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

pe=toc(p);

s=tic;
scores = caffe('forward', {input_data});
el=toc(s);
scores = reshape(scores{1}, options.num_classes,options.batch_size); 
%[scores,sorted_inds]=sort(scores,'descend');
%preds=[scores(1:options.num_preds_to_save,:)', sorted_inds(1:options.num_preds_to_save,:)'-1];
[max_score, max_ind] = max(scores);
preds = [max_ind'-1,max_score']; % 0-indexed
