function new_preds=final_adjust_predictions(images,image_preds,census_ind,class_prior,class_att_prior,att_census_prior,class_census_prior,census_edges,options);
new_preds=image_preds;
num_classes=size(class_census_prior,1);

if options.use_yilun
  census_var_inds=[7,12,23,24];
else
  census_var_inds=census_ind;
end

NUM_ALL_CENSUS_VARS=31;
num_census_vars=numel(census_var_inds);
census_data=zeros(numel([images.group_ids]),NUM_ALL_CENSUS_VARS);

t=1;
if options.use_yilun
  for i=1:numel(images)
    if ~is_good_image(images(i),image_preds(i),census_var_inds,NUM_ALL_CENSUS_VARS)    
      continue;
    end
    for j=1:size(image_preds(i).preds,1)
      if (images(i).classes(j)==-1)
        continue
      end
      census_data(t,:)=images(i).census;
      t=t+1;
    end
  end
  census_data(t:end,:)=[];
  att_census_prior_vec=getCarAttrFromCensus(census_data,census_edges,'price');
end
  
k=1;
for i=1:numel(image_preds)
  fprintf('Adjusting for %d out of %d\n',i,numel(image_preds));
  if ~is_good_image(images(i),image_preds(i),census_var_inds,NUM_ALL_CENSUS_VARS)
    continue;
  end
  c=get_bin(images(i).census(census_ind),census_edges);
  for j=1:size(image_preds(i).preds,1)
    if (images(i).classes(j) ==-1)
      continue;
    end
    if ~options.use_yilun 
      prior=(class_att_prior*att_census_prior(:,c))./class_prior; 
    else
      prior=(class_att_prior*att_census_prior_vec(k,:)')./class_prior; 
      k = k+1;
    end
    classes=image_preds(i).preds(j,num_classes+1:end);
    prior_p=prior(classes+1);
    probs=image_preds(i).preds(j,1:num_classes); 
    new_probs=probs.*prior_p';

    [sorted_probs,inds]=sort(new_probs,'descend');
    new_classes = classes(inds);
    new_preds(i).preds(j,1:num_classes)=sorted_probs;
    new_preds(i).preds(j,num_classes+1:end)=new_classes;
  end
end
if options.use_yilun
  assert(k==t);
end
   
function good_image=is_good_image(image,image_pred,census_var_inds,num_census_vars)
  good_image=~isempty(image_pred.preds) && ...
  numel(image.census~=1) && (numel(image.census)==num_census_vars) && ...
  isempty(find(image.census(census_var_inds)==-1)) && ...
  isempty(find(isnan(image.census(census_var_inds))));
