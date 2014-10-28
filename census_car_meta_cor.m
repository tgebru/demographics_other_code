options.census='acs';
options.level='zipcode';
options.cor='spearman';
options.run_python=false;
options.try_bins=false;

%Get car & census data from db
if options.run_python
  unix(['python val_gt_get_attributes.py ' ... 
    sprintf('%s %s',options.census,options.level)]);
end

car_att_file='val_car_attributes.txt'; 
car_meta_file='car_meta_names.txt';

census_var_file=sprintf('val_%s_variables.txt',options.census);
census_meta_file=sprintf('%s_var_names.txt',options.census);
census_exp_file=sprintf('%s_variables.txt',options.census);

car_attributes=csvread(car_att_file);
census_variables=csvread(census_var_file);


f1=fopen(car_meta_file);
f2=fopen(census_meta_file);
f3=fopen(census_exp_file);
car_attribute_names=textscan(f1,'%s\n');
census_variable_names=textscan(f2,'%s\n');
census_variable_exp=textscan(f3,'%s\n','whitespace','\t');
fclose(f1);
fclose(f2);
fclose(f3);

a_split=regexp(car_attribute_names{1},',','split')
a_split=a_split{1};
c_split=regexp(census_variable_names{1},',','split')
c_split=c_split{1};
census_var_exps=census_variable_exp{1};

j=1;
k=0;
not_there=zeros(200,1);
for i=1:size(census_variables,1)
  k=k+1
  while (census_variables(i,1) ~= car_attributes(k,1)) 
     not_there(j)=k;
     j = j+1;
     k = k+1
     if (census_variables(i,1) == car_attributes(k,1)) 
        break;
     end
  end
end
  
not_there(find(not_there==0))=[];
car_atts=car_attributes;
car_atts(not_there,:)=[];

num_car_attributes=size(car_atts,2);
num_census_vars=size(census_variables,2);

results_corr=zeros(num_car_attributes-1,num_census_vars-1,2);
results_info=zeros(num_car_attributes-1,num_census_vars-1);

%Try out different bins for census variables
num_bins=[100000,10000,1000,100,10]
if options.try_bins
   num_trials=numel(num_bins);
else 
   num_trials=1;
end

max_cor=0;
for nb=1:num_trials
  for a=2:num_car_attributes
    for v=2:num_census_vars
      %[corr,p]=calculate_corr(car_atts(:,a),...
           %census_variables(:,v),a_split{a-1},c_split{v-1},census_var_exps{v-1},options);
       if options.try_bins
         edges=linspace(min(census_variables(:,v)),max(census_variables(:,v)),num_bins(nb));
         [numels,bin_vars]=histc(census_variables(:,v),edges);
       else
         bin_vars=census_variables(:,v);
       end
      %keyboard
      [corr,p]=calculate_corr(car_atts(:,a),...
           bin_vars,a_split{a-1},c_split{v-1},census_var_exps{v-1},options);
      %info=calculate_info(car_attributes(:,a),...
           %census_variables(:,v));
      results_corr(a-1,v-1,1)=corr;
      results_corr(a-1,v-1,2)=p;
      %results_info(a,v)=info;    
    end 
  end

  %Highest correlations
  sorted_corrs=zeros(size(results_corr));
  sorted_census_names=cell(size(results_corr(1,:,1)));
  sigma=0.001;
  sig_corrs=zeros(size(sorted_corrs));
  sig_vars=cell(size(results_corr,1),1);
  for i=1:size(results_corr,1)
    [sorted_corrs(i,:,1), I]=sort(results_corr(i,:,1));
    sorted_corrs(i,:,2)=results_corr(i,I,2)
    sorted_census_names(i,:)=census_var_exps(I)
   
    %Find statistically significant correlations
    inds=find(sorted_corrs(i,:,2)<=sigma & sorted_corrs(i,:,1)~=2);
    sig_corrs(i,1:numel(inds),:)=sorted_corrs(i,inds,:)
    sig_vars{i}=sorted_census_names(i,inds)
    if (max(sig_corrs(i,:,1))>=max_cor)
      max_cor=max(sig_corrs(i,:,1));
      final_corrs=sorted_corrs;
      final_vars=sorted_census_names;
      final_sig_corrs=sig_corrs;
      final_sig_vars=sig_vars;
      final_bins=num_bins(nb);
    end
  end
end

final_corrs
final_vars
final_sig_corrs
final_sig_vars
final_bins
