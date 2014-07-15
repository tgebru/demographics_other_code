%cities={'boston','worcester','springfield'};
clear all;
detected_bboxes_root='/scail/scratch/u/jkrause/gsv_classify/dpm_test/city_results_merged_cal/'
detected_ims_root='/imagenetdb/jkrause/geocar_amt/scripts/city_files/'
detected_files=dir(detected_bboxes_root);
num_files=numel(detected_files);
cities=cell(num_files-2,1);
for i=3:num_files
    cities{i-2}=detected_files(i).name;
end
num_cities=numel(cities);
parfor c=1:num_cities
  f=fopen(sprintf('all_detected_cars_data_%d.txt',c),'w');
  detected_bboxes_file=sprintf('%s%s',detected_bboxes_root,cities{c});
  detected_ims_file=sprintf('%s%s',detected_ims_root,cities{c});
  image_preds=load_files(detected_bboxes_file);
  images=load_files(detected_ims_file);
  image_preds=image_preds.image_preds;
  images=images.images;
  num_ims=numel(images);
  j=0;
  for i= 1:num_ims
    image_name=images(i).im_fname;
    warped=images(i).warped;
    year=images(i).image_year;
    bboxes=image_preds(i).bboxes; 
    num_bboxes=size(bboxes,1);
    fprintf('City %d out of %d\n',c,num_cities)
    if (num_bboxes==0)
      sql_s=sprintf('insert ignore into detected_cars (im_name,warped,year,p1,p2) values("%s",%d,%d,%f,%f)\n',image_name,warped,year,0,0)
      fprintf(f,sql_s);
    end
    for b=1:num_bboxes
      sql_s=sprintf('insert ignore into detected_cars (im_name,warped,year,x1,y1,x2,y2,dpm_random,desc_val,p1,p2) values("%s",%d,%d,%f,%f,%f,%f,%f,%f,%f,%f)\n',image_name,warped,year,bboxes(b,1),bboxes(b,2),bboxes(b,3),bboxes(b,4),bboxes(b,5),bboxes(b,6),bboxes(b,7),bboxes(b,8))
      j=j+1
      i
      fprintf(f,sql_s);
    end
  end
  fclose(f)
end


