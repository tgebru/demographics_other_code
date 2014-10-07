%load validation mat file
save_fname='val_gsv_gt_bboxes.mat';
images=load(save_fname);
images=images.images;
im_names=vertcat({images(:).im_fname});
group_ids=arrayfun(@(x)x.group_ids',images,'UniformOutput',false);
group_ids=vertcat(group_ids{:});
no_predictions=find(group_ids==-1);
group_ids(no_predictions)=[];
num_group_ids=length(group_ids);
price=zeros(num_group_ids,1);

%Get FIPS value for each bbox
if (~isfield(images,'fips'))
  fprintf('getting fips\n')
  images=get_fips_for_ims(images); 
end

save(save_fname,'images');

all_fips=cell(length(group_ids),1);
f=1;
num_ims=numel(images);
for i=1:num_ims
  im_group_ids=images(i).group_ids;
  num_im_group_ids=length(find(im_group_ids ~=-1));
  all_fips(f:f+num_im_group_ids-1)=repmat({images(i).fips},num_im_group_ids,1);
  f = f+num_im_group_ids;
end
  
f1=fopen('val_group_ids.txt','w');
f2=fopen('val_fips.txt','w');

fprintf(f1,'%d\n',group_ids);

for i=1:numel(all_fips)
  fprintf(f2,'%s\n',all_fips{i});
end

fclose(f1);
fclose(f2);
