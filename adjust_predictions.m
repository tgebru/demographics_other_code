function new_preds=adjust_predictions(images,image_preds,census_atts,... 
  input_ims,input_groups,class_prior,class_att_prior,att_census_prior,class_census_prior)

num_preds=numel(image_preds);
num_classes=numel(image_preds(1).preds)*0.5;
%num_classes=length(class_prior);

new_preds=image_preds;

%Get index of input images
num_input_ims=numel(input_ims);
input_indexes=zeros(num_input_ims,1);
im_names=vertcat({images(:).im_fname});
for i=1:num_input_ims
  fprintf('Aligning inputs for %d out of %d\n',i,num_input_ims);
  input_indexes(i)=find(strcmp(im_names,input_ims(i))==1);
end

delta=1e-5;
for i=1:num_input_ims
  fprintf('Adjusting for %d out of %d\n',i,num_input_ims);
  im_ind = input_indexes(i);
  group_indexes=find(images(im_ind).group_ids==input_groups(i));
  assert (~isempty(group_indexes));
  assert(any(images(im_ind).group_ids == input_groups(i)));
  
  for indx=1:numel(group_indexes) 
    group_index=group_indexes(indx); 

    assert(images(im_ind).group_ids(group_index) == input_groups(i)) 
    probs=image_preds(im_ind).preds(group_index,1:num_classes);
    classes=image_preds(im_ind).preds(group_index,num_classes+1:end);

    prior=(class_att_prior*att_census_prior(:,census_atts(i)))./class_prior; 
    %prior=class_census_prior(:,census_atts(i))./class_prior;

    prior_p=prior(classes+1);
    new_probs=probs.*prior_p';

    [sorted_probs,inds]=sort(new_probs,'descend');
    new_classes = classes(inds);
    new_preds(im_ind).preds(group_index,1:num_classes)=sorted_probs;
    new_preds(im_ind).preds(group_index,num_classes+1:end)=new_classes;
  end
  i=i+numel(group_indexes)-1;
end
