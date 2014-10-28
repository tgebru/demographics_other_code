function [class_prior,class_att_prior,att_census_prior]=learn_prior(census_vars,car_vars,group_ids,num_car_atts,num_census_atts,save_path,gsv_weight,options);
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
  catch
    %fprintf('%d\n',group_ids(i));
    not_there=[not_there;group_ids(i)];
    input_classes(i)=-1;
  end
end

%For calculating class prior
web_classes=csvread('web_train_data.txt');
gsv_classes=csvread('gsv_train_data.txt');

web_classes_dict=containers.Map(double(web_classes(:,1)),double(web_classes(:,2)));
gsv_classes_dict=containers.Map(double(gsv_classes(:,1)),double(gsv_classes(:,2)));

car_atts=unique(car_vars);
census_atts=unique(census_vars);

num_classes=numel(class_map.keys());
class_ids=cell2mat(class_map.values());

alpha=1;
%Attribute/census conditional proability table
filename=fullfile(save_path,'att_census_prior.mat')
if ~exist(filename)
  att_census_prior=zeros(num_car_atts,num_census_atts);
  %fprintf('getting attribute/census prior\n')
  for j=1:num_census_atts
    census_inds = find(census_vars == census_atts(j));
    assert(~isempty(census_inds));
    for i=1:num_car_atts
      att_census_prior(i,j)=(nnz(car_vars(census_inds)==car_vars(i)))+alpha;
    end
    att_census_prior(:,j)=att_census_prior(:,j)./sum(att_census_prior(:,j));
  end
  if options.save_priors
    save(filename,'att_census_prior');
  end
else
  cl=load(filename)
  att_census_prior=cl.att_census_prior; 
end

filename=fullfile(save_path,'class_att_prior.mat');
if ~exist(filename)
  class_att_prior=zeros(num_classes,num_car_atts);
  class_prior=zeros(num_classes,1);
  for i=1:num_classes
    %fprintf('getting class/attribute prior for class %d out of %d \n',i,num_classes)
    
    if isKey(gsv_classes_dict,i-1)
      gsv_term=gsv_classes_dict(i-1);
    else
      gsv_term=0;
    end
    class_prior(i)=options.web_weight*web_classes_dict(i-1)+ gsv_weight*gsv_term;
  end
  class_prior=class_prior./(sum(class_prior));

  %Class/attribute conditional probability table
  for j=1:num_car_atts
    att_inds = find(car_vars == car_atts(j));
    assert(~isempty(att_inds));
    for i = 1:num_classes
      class_att_prior(i,j) = nnz(input_classes(att_inds)==class_ids(i));
    end
    class_att_prior(:,j) = class_att_prior(:,j) ./ sum(class_att_prior(:,j));
  end
  if options.save_priors
    save(filename,'class_att_prior','class_prior');
  end
else
  cl=load(filename)
  class_prior=cl.class_prior;
  class_att_prior=cl.class_att_prior;
end
keyboard;
