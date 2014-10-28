function [class_census_prior,class_prior,class_att_prior,att_census_prior]=new_learn_prior(census_vars,car_vars,group_ids,num_census_atts,save_path,gsv_weight,att_map,options);
% class_prior: prior on classes (TODO: calculate w/web data too)
% class_att_prior: P(class|car att) (column is car attribute)
% att_census_prior: P(car att|census) (column is census)

class_map=group_to_class(); 
input_classes=zeros(numel(group_ids),1);
num_examples=numel(group_ids);
not_there=[];
for i=1:num_examples
  try
    input_classes(i)=class_map(group_ids(i));
    car_vars(i)=att_map(input_classes(i));
  catch
    %fprintf('%d\n',group_ids(i));
    not_there=[not_there;group_ids(i)];
    input_classes(i)=-1;
    car_vars(i)=-1;
  end
end

%For calculating class prior
web_classes=csvread('web_train_data.txt');
gsv_classes=csvread('gsv_train_data.txt');
num_total_streetview=sum(gsv_classes(:,2));

web_classes_dict=containers.Map(double(web_classes(:,1)),double(web_classes(:,2)));
gsv_classes_dict=containers.Map(double(gsv_classes(:,1)),double(gsv_classes(:,2)));

%car_atts=unique(car_vars);
car_atts=unique(cell2mat(att_map.values()));
num_car_atts=numel(car_atts);
census_atts=unique(census_vars);

num_classes=numel(class_map.keys());
class_ids=cell2mat(class_map.values());

alpha=1;



%Attribute/census conditional proability table
att_census_prior=zeros(num_car_atts,num_census_atts);
%fprintf('getting attribute/census prior\n')
for j=1:num_census_atts
  census_inds = find(census_vars == census_atts(j));
  assert(~isempty(census_inds));
  for i=1:num_car_atts
    att_census_prior(i,j)=nnz(car_vars(census_inds)==car_atts(i)) +alpha;
  end
  att_census_prior(:,j)=att_census_prior(:,j)./sum(att_census_prior(:,j));
end

class_att_prior=zeros(num_classes,num_car_atts);
class_prior=zeros(num_classes,1);
for i=1:num_classes
  %fprintf('getting class/attribute prior for class %d out of %d \n',i,num_classes)
    
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
  att_streetview_ind=find(car_atts==att_streetview);
  class_att_prior(i,att_streetview_ind)=streetview_class_p;
end

no_atts=find(sum(class_att_prior,1)==0);
class_att_prior(:,no_atts)=[];
for j=1:size(class_att_prior,2)
  class_att_prior(:,j)=class_att_prior(:,j)./sum(class_att_prior(:,j));
end

%Class/census prior
class_census_prior=zeros(num_classes,num_census_atts);
for j=1:num_census_atts
  census_inds = find(census_vars == census_atts(j));
  assert(~isempty(census_inds));
  for i=1:num_classes
    try
      class_census_prior(i,j)=nnz(input_classes(census_inds)==gsv_classes_dict(i-1))+alpha;
    catch
      class_census_prior(i,j)=alpha;
    end
  end
  class_census_prior(:,j)=class_census_prior(:,j)/...
    sum(class_census_prior(:,j));
end
 
save(save_path,'class_census_prior','class_att_prior'...
,'class_prior','att_census_prior');
