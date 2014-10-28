function [class_prior,class_att_prior,att_census_prior]=get_prior(census_vars,car_vars,group_ids,num_car_atts,num_census_atts,save_path);
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
num_examples_with_census = nnz(input_classes~=-1);

car_atts=unique(car_vars);
census_atts=unique(census_vars);

num_classes=length(class_map);
class_ids=cell2mat(class_map.values());

delta=1e-5;
%Attribute/census conditional proability table
filename=fullfile(save_path,'att_census_prior.mat')
if ~exist(filename)
  att_census_prior=zeros(num_car_atts,num_census_atts);
  fprintf('getting attribute/census prior\n')
  for j=1:num_census_atts
    census_inds = find(census_vars == census_atts(j));
    for i=1:num_car_atts
      att_census_prior(i,j)=nnz(car_vars(census_inds)==car_atts(i))/numel(census_inds);
    end
  end
  %att_census_prior(find(att_census_prior==0))=delta; 
  save(filename,'att_census_prior');
else
  cl=load(filename)
  att_census_prior=cl.att_census_prior; 
end

%Class/census conditional probability table
filename=fullfile(save_path,'class_att_prior.mat')
if ~exist(filename)
  class_att_prior=zeros(num_classes,num_car_atts);
  class_prior=zeros(num_classes,1); % TODO: change this for web
  for i=1:num_classes
    fprintf('getting class/attribute prior for class %d out of %d \n',i,num_classes)
    class_prior(i)=nnz(input_classes==class_ids(i))/num_examples_with_census;
  end
  for j=1:num_car_atts
    att_inds = find(car_vars == car_atts(j));
    for i = 1:num_classes
      class_att_prior(i,j) = nnz(input_classes(att_inds)==class_ids(i));
    end
    class_att_prior(:,j) = class_att_prior(:,j) ./ sum(class_att_prior(:,j));
  end
  %class_att_prior(find(class_att_prior==0))=delta;
  %class_prior(find(class_prior==0))=delta;
  %class_att_prior(find(isnan(class_att_prior)))=delta;
  save(filename,'class_att_prior','class_prior');
else
  cl=load(filename)
  class_prior=cl.class_prior;
  class_att_prior=cl.class_att_prior;
end
