car_attributes=csv_read('val_car_attributes.txt'); 
census_variables=csv_read('val_census_variables.txt');
f1=fopen('car_meta_names.txt');
f2=fopen('census_var_names.txt');
car_attribute_names=textscan(f1,'%s\n');
census_variable_names=textscan(f2,'%s\n');
fclose(f1);
fclose(f2);

keyboard;
num_car_attributes=size(car_attributes,2);
num_census_vars=size(census_variables,2);

results_corr=zeros(num_car_attributes,num_census_vars,2);
results_info=zeros(num_car_attributes,num_census_vars);

options.spearman=true;
for a=1:num_car_attributes
  for v=1:num_census_vars
    [corr,p]=calculate_corr(car_attributes(:,a),...
         census_variables(:,v));
    %info=calculate_info(car_attributes(:,a),...
         census_variables(:,v));
    results_corr(a,v,1)=corr;
    results_corr(a,v,2)=p;
    %results_info(a,v)=info;    
  end 
end

function [c,p]= calculate_corr(a,b,options)
  if options.spearman
    [r,p]=corr(a,b,'spearman'); 
  else
    [r,p]=corr(a,b,'pearson'); 
  end

%function info=calculate_info(a,b)

