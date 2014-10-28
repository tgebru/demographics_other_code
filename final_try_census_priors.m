options=set_options();
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
options.learn=true;
options.experiment_with_bins=false;
options.visualize_relation=false;
options.test_components=false;
options.save_priors=false;
options.web_weight=1;
options.use_yilun=false;
options.save_dir='final_prior_res/accs.mat';

if ~exist(options.save_dir)
  mkdir(options.save_dir)
end

%Gett car attributes from census data
if options.use_yilun
  addpath(genpath('/imagenetdb/yilunw/censusToCars/'));
end

%Try out different bins for census variables
gsv_weights=[0.1,0.2,0.3,0.4,0.5,0.75,1];
num_bins=[1,2,4,8,10,12,15,20,30,40,50];

if options.try_bins
   num_trials=numel(num_bins);
   num_car_trials=numel(num_bins);
else 
   num_trials=1;
   num_car_trials=1;
end

%Load validation data
val_save_fname='gsv_val.mat';
if ~exist('val_image_preds', 'var')
  fprintf('load validation data\n');
  tg=load(val_save_fname)
  tg1=load('val_gsv_gt_bboxes.mat');
  val_images=tg.val_images;
  val_image_preds=tg1.image_preds;
  fprintf('done\n');
end

train_save_fname='gsv_train.mat';
if ~exist('train_image_preds', 'var')
  fprintf('load training data\n');
  tg=load(train_save_fname)
  train_images=tg.train_images;
  fprintf('done\n');
end

%Find out initial accuracy
%[ap, acc, ac5,num_fg_eval] = gsv_eval(images,image_preds,options)
%max_acc=acc;
%max_ac5=ac5;
max_acc=0.3127;
max_ac5=0.578;

num_car_attributes=5;
num_census_vars=31;

ac_cnt=1;
relevant_variables=[4,12,13,29];
num_census_vars=numel(relevant_variables)
all_accs=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
all_ac5=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
%r=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
%p=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
%rb=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));
%pb=zeros(num_car_attributes,num_census_vars,num_trials,num_car_trials,numel(gsv_weights));

%Loop over different census/car vars with diff number of bins
for g=1:numel(gsv_weights)
  for a=1:1%num_car_attributes
    for v=relevant_variables
      for nb=1:num_trials
        if a>2 
           num_car_bins=1;
           num_car_trials=1;
        end
        %num_car_bins=nb;
        for num_car_bins=1:num_car_trials
          save_path=fullfile(options.save_dir,sprintf('%d_%d_%d_%d_%0.2f.mat',a,v,num_bins(nb),num_bins(num_car_bins),gsv_weights(g)));

          %Plot values
          if options.visualize_relation
            [rc,pc,rbc,pbc,cmat]=visualize_relation(train_images,a,v,save_path,options);
            %r(a,v,nb,num_car_bins,g)=rc;
            %p(a,v,nb,num_car_bins,g)=pc;
            %rb(a,v,nb,num_car_bins,g)=rbc;
            %pb(a,v,nb,num_car_bins,g)=pbc;
          end

          %Learn priors 
          if options.learn
            fprintf('Getting priors\n')
            [class_census_prior,class_prior,class_att_prior,att_census_prior,census_edges]=final_learn_prior(train_images,nb,num_car_bins,v,save_path,gsv_weights(g),options);

            %Multiply the predictions by the priors
            fprintf('adjusting priors\n')
            att_census_prior_p=ones(size(att_census_prior));
            image_preds_prior=final_adjust_predictions(val_images,val_image_preds,v,class_prior,class_att_prior,att_census_prior,class_census_prior,census_edges,options);
            fprintf('evaluating\n');
            [ap,ac,ac5,num_fg_eval]=gsv_eval(val_images,image_preds_prior,options) 
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

save(fullfile(options.save_dir,'accs.mat'),'all_accs','all_ac5','max_acc','max_ac5');
[best_car_ind,best_census_ind,best_cens_bin,best_car_bin]=ind2sub(size(all_accs),find(all_accs(:)==max(all_accs(:))));
[best_car_ind5,best_census_ind5,best_cens_bin5,best_car_bin5]=ind2sub(size(all_ac5),find(all_ac5(:)==max(all_ac5(:))));
