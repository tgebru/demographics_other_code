function [ptime,input_data]=resize_ims(ims,bboxes,options)

s=tic;
num_bboxes = size(bboxes, 1);

d = load(options.mean_fname);
IMAGE_MEAN = d.image_mean;
RESIZE_DIMS = options.resize_dims;
CROPPED_DIM = options.cropped_dim;

input_data = zeros(CROPPED_DIM,CROPPED_DIM, 3, options.batch_size, 'single');

for i=1:num_bboxes
  im=ims{i};
  
  x1 = bboxes(i,1);
  y1 = bboxes(i,2);
  x2 = bboxes(i,3);
  y2 = bboxes(i,4);

  imr = single(imresize(im(y1:y2,x1:x2,[3 2 1]),...
     RESIZE_DIMS, 'nearest', 'antialiasing', false))-IMAGE_MEAN;

  input_data(:,:,:,i)=permute(imresize(imr,[CROPPED_DIM,CROPPED_DIM],...
    'nearest','antialiasing',false),[2 1 3]); 
end
ptime=toc(s);
