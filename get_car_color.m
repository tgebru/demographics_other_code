cities={'boston','worcester','springfield'};
num_cities=numel(cities)
for c=1:1 %num_cities
  detected_bboxes_file=sprintf('/scail/scratch/u/jkrause/gsv_classify/dpm_test/results_%s/131045_1_0_0.mat',cities{c})
  detected_ims_file=sprintf('/imagenetdb/jkrause/geocar_amt/scripts/city_files/%s_massachusetts.mat',cities{c})

  dbname='boston_cars';
  username='tgebru';
  password='';
  driver='com.mysql.jdbc.Driver';
  dburl = ['jdbc:mysql://imagenet.stanford.edu:3306/' dbname];
  javaclasspath('/imagenetdb/tgebru/cars/demographics/boston_cars/code/mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');

  load(detected_bboxes_file)
  load(detected_ims_file)

  num_ims=numel(images)
  j=0
  filename='ma_detected_cars_data.txt';
  f=fopen(filename,'w');
  for i=1:1%num_ims
    image_name=images(i).im_fname;
    warped=images(i).warped;
    year=images(i).image_year;
    bboxes=image_preds(i).bboxes; 
    num_bboxes=size(bboxes,1);
    if (num_bboxes~=0)
      for b=1:num_bboxes
        b
        bbox=bboxes(b,:);
        image=imread(image_name);
        if bbox(end-1)>=0.7
          imcrop=image(bbox(2):bbox(4),bbox(1):bbox(3),:);
          figure,
          imshow(imcrop);
        end
      end
    end
  end
  fclose(f)
end


