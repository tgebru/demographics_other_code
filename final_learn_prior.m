function [class_census_prior,class_prior,class_att_prior,att_census_prior,census_edges]=final_learn_prior(images,num_census_atts,num_car_atts,census_ind,save_path,gsv_weight,options);

% class_prior: prior on classes (TODO: calculate w/web data too)
% class_att_prior: P(class|car att) (column is car attribute)
% att_census_prior: P(car att|census) (column is census)

class_map=group_to_class(); 

%For calculating class prior
web_classes=csvread('web_train_data.txt');
gsv_classes=csvread('gsv_train_data.txt');
num_total_streetview=sum(gsv_classes(:,2));

web_classes_dict=containers.Map(double(web_classes(:,1)),double(web_classes(:,2)));
gsv_classes_dict=containers.Map(double(gsv_classes(:,1)),double(gsv_classes(:,2)));

census_mask=arrayfun(@(x)x.census(1)~=-1,images);
ims_w_census_inds=find(census_mask ~=0);
ims_w_census=images(ims_w_census_inds);
all_census_vars=vertcat(ims_w_census.census);
cur_census_var=all_census_vars(:,census_ind);
cur_census_var_ind=find(~isnan(cur_census_var)&cur_census_var>=0);
cur_census_var=cur_census_var(cur_census_var_ind);
ims_w_census=ims_w_census(cur_census_var_ind);

num_classes=numel(class_map.keys());
class_ids=cell2mat(class_map.values());

[numels,census_edges,census_vars]=bin_vars(cur_census_var,num_census_atts); 
census_atts=unique(census_vars);

%Get car attribute map
att_map=class_to_priceid_map(num_car_atts);
att_map_values=cell2mat(att_map.values());
att_map_mat=[(0:num_classes-1)',att_map_values'];
car_atts=unique(att_map_values);

alpha=1;

%Attribute/census conditional proability table
att_census_prior=zeros(num_car_atts,num_census_atts);
fprintf('getting attribute/census prior\n')
for j=1:num_census_atts
  census_inds = find(census_vars == census_atts(j));
  assert(~isempty(census_inds));
  for i=1:num_car_atts
    classes=[ims_w_census(census_inds).classes];
    classes(find(classes==-1))=[];
    cur_car_atts=att_map_mat(classes+1,2);
    att_census_prior(i,j)=nnz(cur_car_atts==car_atts(i))+alpha;
  end
  att_census_prior(:,j)=att_census_prior(:,j)./sum(att_census_prior(:,j));
end

class_att_prior=zeros(num_classes,num_car_atts);
class_prior=zeros(num_classes,1);
for i=1:num_classes
  fprintf('getting class/attribute prior for class %d out of %d \n',i,num_classes)
    
  if isKey(gsv_classes_dict,i-1)
      gsv_term=gsv_classes_dict(i-1);
  else
      gsv_term=0;
  end
  class_prior(i)=alpha+options.web_weight*web_classes_dict(i-1)+ gsv_weight*gsv_term;
end
class_prior=class_prior./(sum(class_prior));


%Class/attribute conditional probability table
for i = 1:num_classes
  try
    streetview_class_p=gsv_classes_dict(i-1)+alpha;
  catch
    streetview_class_p=alpha;
  end
  att_streetview=att_map(i-1);  
  class_att_prior(i,att_streetview)=streetview_class_p;
end

for j=1:num_car_atts
  class_att_prior(:,j)=class_att_prior(:,j)./sum(class_att_prior(:,j));
end

%Class/census prior
class_census_prior=zeros(num_classes,num_census_atts);
%{
for j=1:num_census_atts
  census_inds = find(census_vars == census_atts(j));
  assert(~isempty(census_inds));
  for i=1:num_classes
    fprintf('Getting class census prior for %d out of %d census %d out of %d\n',i,num_classes,j,num_census_atts);
    try
      class_census_prior(i,j)=nnz([ims_w_census(census_inds).classes]==(i-1))+alpha;
    catch
      class_census_prior(i,j)=alpha;
    end
  end
  class_census_prior(:,j)=class_census_prior(:,j)/...
    sum(class_census_prior(:,j));
end
%} 

save(save_path,'att_census_prior','class_att_prior','class_prior','class_census_prior');
