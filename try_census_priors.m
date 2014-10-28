options=set_options();
options.census='acs';
options.level='zipcode'
options.run_python=false;
options.try_bins=true
options.test_all=false;
options.test_make=false;
options.test_submodel=false;
options.test_price=false;
options.test_foreign=false;
options.test_country=false;
options.test_model=false;
options.visualize_results=false;

%Get car & census data from db
if options.run_python
  unix(['python val_gt_get_attributes.py ' ... 
    sprintf('%s %s train',options.census,options.level)]);

  unix(['python val_gt_get_attributes.py ' ... 
    sprintf('%s %s val',options.census,options.level)]);
end

car_att_file='train_car_attributes.txt'; 
car_meta_file='car_meta_names.txt';

census_var_file=sprintf('train_%s_variables.txt',options.census);
census_meta_file=sprintf('%s_var_names.txt',options.census);
census_exp_file=sprintf('%s_var_exps.txt',options.census);
val_census_atts_file=sprintf('val_%s_variables.txt',options.census);

car_attributes=csvread(car_att_file);
census_variables=csvread(census_var_file);
val_census_atts=csvread(val_census_atts_file);

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

%Figure out which training data census variables are missing
j=1;
k=0;
not_there=zeros(200000,1);
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
%num_bins=[10,100,1000,10000]
num_bins=[1]
if options.try_bins
   num_trials=numel(num_bins);
   num_car_trials=numel(num_bins);
else 
   num_trials=1;
   num_car_trials=1;
end

%Load validation data
save_fname='val_gsv_gt_bboxes.mat';
if ~exist('image_preds', 'var')
  fprintf('load\n');
  load(save_fname)
  fprintf('done\n');
end

[ap, acc, num_fg_eval] = gsv_eval(images,image_preds,options)
max_acc=acc;
all_accs=zeros(num_car_attributes-1*num_census_vars-1*num_trials*num_car_trials,1);
group_ids=car_attributes(:,1);
ac_cnt=1;

%Figure out which validations data census variables are missing for
k=0;
val_groups=[images(:).group_ids];
val_groups=val_groups(find(val_groups ~= -1));
new_val_census_atts=zeros(numel(val_groups),size(val_census_atts,2));
for i=1:size(val_census_atts,1)
  k=k+1;
  if (val_census_atts(i,1)==val_groups(k))
      new_val_census_atts(k,:)=val_census_atts(i,:);
  else
    
    while (val_census_atts(i,1) ~= val_groups(k)) 
      new_val_census_atts(k,:)=-1*ones(size(new_val_census_atts(k,:)));
      k = k+1
      if (val_census_atts(i,1) == val_groups(k)) 
         new_val_census_atts(k,:)=val_census_atts(i,:);
         break;
      end
    end
  end
end

for a=2:num_car_attributes
  for v=2:num_census_vars
    no_inds=find(census_variables(:,v)==-1);
    cvars=census_variables(:,v);  
    cvars(no_inds)=[];
    cur_car_atts=car_atts(:,a);
    cur_car_atts(no_inds)=[];
    for nb=1:num_trials
      for num_car_bins=1:num_car_trials
        census_quantiles=linspace(0,1,num_bins(nb));
        car_quantiles=linspace(0,1,num_bins(num_car_bins));

        edges=quantile(cvars,census_quantiles);
        car_edges=quantile(cur_car_atts,car_quantiles);

        [numels,census_bin_vars]=histc(cvars,edges);
        [num_val_els,new_val_census_atts_bin]=histc(new_val_census_atts(:,v),edges);
        [num_carels,car_bin_vars]=histc(cur_car_atts,car_edges);

        save_path=sprintf('./priors/%d_%d_%d_%d',a,v,num_bins(nb),num_bins(num_car_bins));
        if ~exist(save_path)
          mkdir(save_path);
        end
        [class_prior,class_att_prior,att_census_prior]=get_prior(census_bin_vars,car_bin_vars,group_ids,num_bins(num_car_bins),num_bins(nb),save_path);

        %multiply the predictions by the priors
        image_preds_prior=adjust_predictions(images,image_preds,new_val_census_atts_bin,class_prior,class_att_prior,att_census_prior);

        [ap,ac,num_fg_eval]=gsv_eval(images,image_preds_prior,options) 
        all_accs(ac_cnt)=ac;
        ac_cnt=ac_cnt+1;
keyboard;
      end
    end 
  end
end
