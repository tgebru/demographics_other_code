cities={'boston_massachusetts.mat',...}
        'san antonio_texas.mat'}
detected_ims_root='/home/jkrause/gsv_data/city_files';
dest_dir_root='/home/tgebru/geo/unwarped_ims';
    
cache=false;

if cache
  for c=2:length(cities)
    detected_ims_file=fullfile(detected_ims_root,cities{c});
    images=load(detected_ims_file);
    im_names={images.images.im_fname};
    num_ims_to_copy=min(1000,length(im_names))
    for i=1:num_ims_to_copy %length(im_names)
      tic
      fprintf('image %d in city %d\n',i,c);
      name=im_names{i}(findstr('gsv',im_names{1})+length('gsv/'):end);
      dest_name= fullfile(dest_dir_root,name);
      dest_dir=fullfile(dest_dir_root,fileparts(name)); 
      
      rest_dir=dest_dir;
      parent_dir='/';
      while true 
        [token,remain]=strtok(rest_dir,'/');
        parent_dir=fullfile(parent_dir,token);
        if (~exist(parent_dir))
          mkdir(parent_dir);
        end
        if(isempty(remain))
          break;
        end
        rest_dir=remain;
       end
       toc   
      copyfile(im_names{i},dest_name);
    end
  end
end

num_reps=5;
times=cell(2,2,num_reps);
inds=cell(2,2,num_reps);
options=set_options();
avg_times=zeros(2,2);
for c=1: 2 %length(cities)
  for opt=0:1
    for i=1:num_reps
      fprintf('city %d rep %d opt %d\n',c,i,opt);
      %DPM predictions
      detected_bboxes_file=fullfile(options.detected_bboxes_root,cities{c});

      %Image files
      detected_ims_file=fullfile(options.detected_ims_root,cities{c});

      image_preds=load(detected_bboxes_file);
      image_preds=image_preds.image_preds;

      images=load(detected_ims_file);
      images=images.images;

      [image_preds(:).im_fname]=images.im_fname;
      image_preds(1).preds=[];

      options.evalac=opt;
      options.data_dir=dest_dir_root;
      [y,ind]=gsv_classify_test_caching(images(1:1000),image_preds(1:1000),'',options);
      times{c,opt+1,i}=[times{c,opt+1,i};y];      
      inds{c,opt+1,i}=[inds{c,opt+1,i};ind];      
    end
    avg_times(c,opt+1)=mean(mean(times{c,opt+1}))
  end
end

