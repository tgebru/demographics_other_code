images=load('/imagenetdb/jkrause/geocar_amt/scripts/gsv_train');
images=images.images;
num_ims=numel(images);
f=fopen('train_gt_cars_data.txt','w');

for i= 1:num_ims
  image_name=images(i).im_fname;
  bboxes=images(i).bboxes; 
  num_bboxes=size(bboxes,1);
  if (num_bboxes==0)
    sql_s=sprintf('insert ignore into train_gt_detected_cars (im_name) values("%s")\n',image_name)
    fprintf(f,sql_s);
  end
  for b=1:num_bboxes
    sql_s=sprintf('insert ignore into train_gt_detected_cars (im_name,x1,y1,x2,y2,group_id) values("%s",%d,%d,%d,%d,%d)\n',image_name,bboxes(b,1),bboxes(b,2),bboxes(b,3),bboxes(b,4),images(i).group_ids(b));
    fprintf('writing bbox #%d',b);
    fprintf(f,sql_s);
  end
end
fclose(f)


