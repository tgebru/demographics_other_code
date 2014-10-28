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
options.draw_figure=true;
options.learn=false;
options.experiment_with_bins=false;
options.visualize_relation=false;
options.test_components=false;
options.save_priors=false;
options.web_weight=1;
options.save_dir='./new_priors';

if ~exist(options.save_dir)
  mkdir(options.save_dir);
end

%Get car & census data from db
if options.run_python
  unix(['python gt_get_attributes.py ' ... 
    sprintf('%s %s train',options.census,options.level)]);

  unix(['python gt_get_attributes.py ' ... 
    sprintf('%s %s val',options.census,options.level)]);
end

%Load data
car_att_file='train_car_attributes.txt'; 
val_car_att_file='val_car_attributes.txt'; 
car_meta_file='car_meta_names.txt';
census_var_file=sprintf('train_%s_variables.txt',options.census);
census_meta_file=sprintf('%s_var_names.txt',options.census);
census_exp_file=sprintf('%s_variables.txt',options.census);
val_census_atts_file=sprintf('val_%s_variables.txt',options.census);
train_ims_file=sprintf('train_image_names.txt');
val_ims_file=sprintf('val_image_names.txt');

car_attributes=csvread(car_att_file);
census_variables=csvread(census_var_file);
val_census_variables=csvread(val_census_atts_file);
val_car_attributes=csvread(val_car_att_file);

f1=fopen(car_meta_file);
f2=fopen(census_meta_file);
f3=fopen(census_exp_file);
f4=fopen(train_ims_file);
f5=fopen(val_ims_file);

car_attribute_names=textscan(f1,'%s\n');
census_variable_names=textscan(f2,'%s\n');
census_variable_exp=textscan(f3,'%s\n','whitespace','\t');
train_ims=textscan(f4,'%s\n');
val_ims=textscan(f5,'%s\n');
train_ims=train_ims{1};
val_ims=val_ims{1};
fclose(f1);
fclose(f2);
fclose(f3);
fclose(f4);
fclose(f5);

%Try out different bins for census variables
gsv_weights=[0.1,0.2,0.3,0.4];
num_bins=[1,2,4,8,10,12,15,20];

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
  tg=load(save_fname)
  images=tg.images;
  image_preds=tg.image_preds;
  fprintf('done\n');
end

%Find out initial accuracy
%[ap, acc, ac5,num_fg_eval] = gsv_eval(images,image_preds,options)
%max_acc=acc;
%max_ac5=ac5;
max_acc=0.3127;
max_ac5=0.578;

num_car_attributes=size(car_attributes,2);
num_census_vars=size(census_variables,2);

all_accs=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
all_ac5=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
r=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
p=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
rb=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
pb=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));

group_ids=car_attributes(:,1);
val_group_ids=val_car_attributes(:,1);
ac_cnt=1;

relevant_variables=[5,13,14,30]
%Loop over different census/car vars with diff number of bins
for g=1:numel(gsv_weights)
  for a=[2:7]
    for v= relevant_variables(1)
      %Get rid of indicies with no census data for train
      if a>6
        a_ind=6;
      else
        a_ind=a;
      end
      [no_inds,cur_census_vars,cur_car_atts,cur_groups,cur_ims]=get_rid_of_nulls(census_variables(:,v),car_attributes(:,a_ind),group_ids,train_ims);

      %Get rid of indicies with no census data for validation
      [val_no_inds,val_cur_census_vars,val_cur_car_atts,val_cur_groups,val_cur_ims]...
        =get_rid_of_nulls(val_census_variables(:,v),...
          val_car_attributes(:,a_ind),val_group_ids,val_ims);

      options.bin_cars=true;
      for nb=7%1:num_trials
        if a>2 
           num_car_trials=1;
           options.bin_cars=false;
           num_car_bins=1;
           num_cur_car_bins=0;
        %else
        %  num_car_bins=nb;
        end
        [att_map,num_cur_car_bins]=get_att_map(a,num_cur_car_bins);
        for num_car_bins=nb %1:num_car_trials
          %Create bins
          census_quantiles=linspace(0,1,num_bins(nb)+1);

          census_edges=unique(quantile(cur_census_vars,census_quantiles));

          %Put data in bins
          [numels,census_bin_vars]=histc(cur_census_vars,[census_edges(1:end-1),census_edges(end)+1]);
          [num_val_els,val_census_bin_vars]=histc(val_cur_census_vars,[census_edges(1:end-1),census_edges(end)+1]);
          if options.bin_cars
            car_quantiles=linspace(0,1,num_bins(num_car_bins)+1);
            car_edges=unique(quantile(cur_car_atts,car_quantiles));
            [num_carels,car_bin_vars]=histc(cur_car_atts,[car_edges(1:end-1),car_edges(end)+1]);
          else
            car_bin_vars=cur_car_atts;
          end

          save_path=fullfile(options.save_dir,sprintf('%d_%d_%d_%d_%0.2f',a,v,num_bins(nb),num_bins(num_car_bins),gsv_weights(g)));


          %Plot values
          if options.visualize_relation
            [rc,pc,rbc,pbc,cmat]=visualize_relation(car_bin_vars,census_bin_vars,cur_car_atts,cur_census_vars,a,v,nb,num_car_bins,save_path,options);
            
            r(a,v,nb,num_car_bins,g)=rc;
            p(a,v,nb,num_car_bins,g)=pc;
            rb(a,v,nb,num_car_bins,g)=rbc;
            pb(a,v,nb,num_car_bins,g)=pbc;
          end

          %Learn priors 
          if options.learn
            num_cur_census_bins=numel(census_edges)-1;
            if options.bin_cars
              num_cur_car_bins=numel(car_edges)-1;
            end
            
            fprintf('Getting priors\n')
            %[class_prior,class_att_prior,att_census_prior]=learn_prior(census_bin_vars,car_bin_vars,cur_groups,num_cur_car_bins,num_cur_census_bins,save_path,gsv_weights(g),options);
            [class_census_prior,class_prior,class_att_prior,att_census_prior]=new_learn_prior(census_bin_vars,car_bin_vars,cur_groups,num_cur_census_bins,save_path,gsv_weights(g),att_map,options);

            %Multiply the predictions by the priors
            fprintf('adjusting priors\n')
            att_census_prior_p=ones(size(att_census_prior));
            image_preds_prior=multiply_adjust_predictions(images,image_preds,val_census_bin_vars,val_cur_ims,val_cur_groups,class_prior);
            fprintf('evaluating\n');
            [ap,ac,ac5,num_fg_eval]=gsv_eval(images,image_preds_prior,options) 
            all_accs(a,v,nb,num_car_bins,g)=ac;
            all_ac5(a,v,nb,num_car_bins,g)=ac5;
            ac_cnt=ac_cnt+1;
            fprintf('Done %d out of %d\n',ac_cnt,numel(all_accs));
            fprintf('Done g=%d,a=%d,v=%d,nb=%d,num_car_bins=%d\n',g,a,v,nb,num_car_bins);
            if (ac>max_acc)
               max_acc=ac;
            end
            if (ac5>max_ac5)
               max_ac5=ac5;
            end
          end
        end
      end
    end
  end
end

save(fullfile(options.save_dir,'att2_accs.mat'),'all_accs','all_ac5','max_acc','max_ac5');

[best_car_ind,best_census_ind,best_cens_bin,best_car_bin]=ind2sub(size(all_accs),find(all_accs(:)==max(all_accs(:))));

[best_car_ind5,best_census_ind5,best_cens_bin5,best_car_bin5]=ind2sub(size(all_ac5),find(all_ac5(:)==max(all_ac5(:))));
