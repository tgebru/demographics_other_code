%Load validation data
addpath(genpath('/afs/cs.stanford.edu/u/tgebru/software/liblinear-1.94'));

NUM_CENSUS_VARS=31;
num_bins=[2,4,8,10,12,15,20];
save_dir='logistic_regression';
if ~exist(save_dir)
  mkdir(save_dir)
end

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

for nb=1:numel(num_bins)
  fprintf('Get training census data/price\n')
  [train_census,train_price]=get_census_price(...
    train_images,num_bins(nb),NUM_CENSUS_VARS);

  fprintf('Get validation census data/price\n')
  [val_census,val_price]=get_census_price(...
    val_images,num_bins(nb),NUM_CENSUS_VARS);

  %Train SVM
  c=[2^-5,2^-3,2^-1,2^1,2^3,2^5,2^7,2^9,2^11,2^13,2^15];
  reg=[0,6]; %L1 vs L2 reg logistic regression
  norm_ind=[0,1,2,3];
  accuracy=zeros(numel(num_bins),numel(c),numel(norm_ind),numel(reg));
  max_acc=0;

  for r=1:numel(reg)
    for n=1:numel(norm_ind)
      val_census_n=zeros(size(val_census));
      train_census_n=zeros(size(train_census));
      for i=1:size(train_census,2)
        if norm_ind(n) ~=3
          train_census_n(:,i)=train_census(:,i)./norm(train_census(:,i),norm_ind(n));
          val_census_n(:,i)=val_census(:,i)./norm(train_census(:,i),norm_ind(n));
        else
          train_census_n(:,i)=train_census(:,i)./max(train_census(:,i));
          val_census_n(:,i)=val_census(:,i)./max(train_census(:,i));
        end
      end

      for c_ind=1:numel(c)
        model = train(double(train_price), sparse(double(train_census_n)),sprintf('-s %d -c %f',reg(r),c(c_ind)));
        [predicted_label, acc, decision_values] = predict(double(val_price),sparse(double(val_census_n)),model, '-b 1');
        accuracy(nb,c_ind,n,r)=acc(1);
        save_path=fullfile(save_dir,sprintf('%d_%d_%d_%d',num_bins(nb),c_ind,norm_ind(n),reg(r)));
        save(save_path,'predicted_label','acc','decision_values');
        if acc(1)>max_acc
          max_acc=acc(1);
        end
        fprintf('%d %d %d %d\n',nb,c_ind,n,r);
      end
    end
  end
  max_acc
end
