function [ap, acc, ac5,num_fg_eval] = gsv_eval(gt_data, pred_data, options)
% gt_data: im_fname, bboxes, group_ids, classes, big_enough
% both arguments have fields bboxes
% pred_data also has preds
minoverlap = 0.5;
assert(numel(gt_data) == numel(pred_data));
num_ims = numel(gt_data);
num_classes=0.5*numel(pred_data(1).preds);

% Remove boxes which are too small.
gt_data = remove_small_boxes(gt_data, options,0);
pred_data=get_scores(pred_data,options);
pred_data = remove_small_boxes(pred_data, options,1);

gt_bboxes = arrayfun(@(x)x.bboxes, gt_data, 'uniformoutput', false);
gt_classes = arrayfun(@(x)x.classes, gt_data, 'uniformoutput', false);
num_gt_boxes = sum(cellfun(@(x)size(x, 1), gt_bboxes));

pred_bboxes = arrayfun(@(x)x.bboxes, pred_data, 'uniformoutput', false);
pred_classes = arrayfun(@(x)x.preds, pred_data, 'uniformoutput', false);
num_pred_boxes = sum(cellfun(@(x)size(x, 1), pred_bboxes));
[all_pred_bboxes, all_pred_classes, im_nums] = sort_pred_bboxes(pred_bboxes, pred_classes);

tp=zeros(num_pred_boxes,1);
fp=zeros(num_pred_boxes,1);

det_gt_classes = zeros(num_gt_boxes, 1); % Overallocate
det_pred_classes = zeros(num_gt_boxes, num_classes);
det_pred_probs = zeros(num_gt_boxes, num_classes);
det_pred_ind = 1;

detected_pred_bboxes=cell(num_ims,1);
detected=cell(num_ims,1);

for pred_ind=1:num_pred_boxes
  fprintf('calulating detection box %d of %d\n', pred_ind, num_pred_boxes);
  num_gt_im_boxes = size(gt_bboxes{im_nums(pred_ind)}, 1);
  if isempty(detected{im_nums(pred_ind)})
    detected{im_nums(pred_ind)}=zeros(num_gt_im_boxes,1);
  end
  bb=all_pred_bboxes(pred_ind,:);
  ovmax=-inf;
  for g=1:num_gt_im_boxes
    bbgt=gt_bboxes{im_nums(pred_ind)}(g,:); 
    bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
    iw=bi(3)-bi(1)+1;
    ih=bi(4)-bi(2)+1;
    if iw>0 & ih>0                
      % compute overlap as area of intersection / area of union
      ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
        (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
        iw*ih;
      ov=iw*ih/ua;
      if ov>ovmax
        ovmax=ov;
        jmax=g;
      end
    end
  end
  % assign detection as true positive/don't care/false positive
  im_detected=detected{im_nums(pred_ind)};
  if ovmax>=minoverlap
    if ~im_detected(jmax)
      tp(pred_ind)=1; %true positive
      detected{im_nums(pred_ind)}(jmax)=1;
      detected_pred_bboxes{im_nums(pred_ind)}=[detected_pred_bboxes{im_nums(pred_ind)};bb]; 
      % Fine-grained
      gt_class = gt_classes{im_nums(pred_ind)}(jmax);
      if gt_class ~= -1 % -1 means it wasn't annotated/we don't know
        det_gt_classes(det_pred_ind) = gt_classes{im_nums(pred_ind)}(jmax);
        det_pred_classes(det_pred_ind,:) =all_pred_classes(pred_ind,1:num_classes);
        det_pred_probs(det_pred_ind,:) =all_pred_classes(pred_ind,1+num_classes:end);
        det_pred_ind = det_pred_ind + 1;
      end
    else
      fp(pred_ind)=1;%false positive (multiple detections)
    end
  else
    fp(pred_ind)=1; %false positive 
  end
end

% compute precision/recall
npos=num_gt_boxes;
fp=cumsum(fp);
tp=cumsum(tp);

det_gt_classes = det_gt_classes(1:det_pred_ind-1);
det_pred_classes = det_pred_classes(1:det_pred_ind-1,:);
det_pred_probs = det_pred_probs(1:det_pred_ind-1,:);
num_fg_eval = numel(det_pred_classes(:,1));
if num_fg_eval > 0
  acc = mean(det_gt_classes == det_pred_classes(:,1));
  ac5=mean(det_gt_classes==det_pred_classes(:,1) |...
           det_gt_classes==det_pred_classes(:,2) |...
           det_gt_classes==det_pred_classes(:,3) |...
           det_gt_classes==det_pred_classes(:,4) |...
           det_gt_classes==det_pred_classes(:,5) ...
          );
else
  acc = 0;
end

%{
name_map = class_to_name_map();
for i = 1:numel(det_gt_classes)
  fprintf('\npred: %s\ngt: %s\n', name_map(det_pred_classes(i)), name_map(det_gt_classes(i)));
end
%}


rec=tp/npos;
prec=tp./(fp+tp);
ap=VOCap(rec,prec)
acc

%Plot images
if options.visualize_results
  for i = 1:numel(gt_data)
    fprintf('Image %d\n', i);
    fprintf('GT\n');
    im = imread(fullfile('/data/jkrause/gsv_100k_unwarp', gt_data(i).im_fname));
    vis_preds(im, horzcat(gt_data(i).bboxes, ones(size(gt_data(i).bboxes, 1), 1)), horzcat(gt_data(i).classes(:), ones(numel(gt_data(i).classes), 1)));
    fprintf('pred\n');
   % vis_preds(im, pred_data(i).bboxes, pred_data(i).preds);
    keyboard;
  end
end

if options.test_all
  plot_fg_results(det_gt_classes,det_pred_classes,acc);
end

%Aggregate by make and do tests
if options.test_make
  make_map = class_to_makeid_map();
  make_names_map=make_class_to_makename_map();
  for i=1:numel(det_gt_classes)
    det_gt_makes(i)=make_map(det_gt_classes(i));
    det_pred_makes(i)=make_map(det_pred_classes(i));
  end
  acc_make=mean(det_gt_makes == det_pred_makes)
  all_ms=make_map.values;
  all_makes=unique([all_ms{:}]);
  make_names=cell(numel(all_makes),1);
  for m=1:numel(all_makes)
    make_names{m}=make_names_map(all_makes(m));
  end

  plot_fg_results(det_gt_makes,det_pred_makes,'makes',make_names,all_makes',acc_make);
end

%Aggregate by submodel and do tests
if options.test_submodel
  submodel_map = class_to_submodelid_map();
  submodel_names_map=submodel_class_to_submodelname_map();
  for i=1:numel(det_gt_classes)
    det_gt_submodels(i)=submodel_map(det_gt_classes(i));
    det_pred_submodels(i)=submodel_map(det_pred_classes(i));
  end
  acc_submodel=mean(det_gt_submodels == det_pred_submodels)
  all_subs=submodel_map.values;
  all_submodels=unique([all_subs{:}]);
  submodel_names=cell(numel(all_submodels),1);
  for s=1:numel(all_submodels)
    submodel_names{s}=submodel_names_map(all_submodels(s));
  end

  plot_fg_results(det_gt_submodels,det_pred_submodels,'submodels',submodel_names,all_submodels',acc_submodel);
end

%Aggregate by price and do tests
if options.test_price
  options.num_price_bins=10;
  price_map = class_to_priceid_map(options.num_price_bins);
  price_names_map=price_class_to_pricename_map();
  for i=1:numel(det_gt_classes)
    det_gt_prices(i)=price_map(det_gt_classes(i));
    det_pred_prices(i)=price_map(det_pred_classes(i));
  end
  acc_prices=mean(det_gt_prices == det_pred_prices)
  all_prices=price_map.values;
  all_prices=unique([all_prices{:}]);
  price_names=cell(numel(all_prices),1);
  for s=1:numel(all_prices)
    price_names{s}=price_names_map(all_prices(s));
  end

  plot_fg_results(det_gt_prices,det_pred_prices,'prices',price_names,all_prices',acc_price);
end

%Aggregate by domestic/foreign
if options.test_foreign
  foreign_map = class_to_foreignid_map();
  foreign_names_map=foreign_class_to_foreignname_map();
  for i=1:numel(det_gt_classes)
    det_gt_foreign(i)=foreign_map(det_gt_classes(i));
    det_pred_foreign(i)=foreign_map(det_pred_classes(i));
  end
  acc_foreign=mean(det_gt_foreign == det_pred_foreign)
  all_foreign=foreign_map.values;
  all_foreign=unique([all_foreign{:}]);
  foreign_names=cell(numel(all_foreign),1);
  for s=1:numel(all_foreign)
    foreign_names{s}=foreign_names_map(all_foreign(s));
  end

  plot_fg_results(det_gt_foreign,det_pred_foreign,'domestic/foreign',foreign_names,all_foreign',acc_foreign);
end

%Aggregate by country and do tests
if options.test_country
  country_map = class_to_countryid_map();
  country_names_map=country_class_to_countryname_map();
  for i=1:numel(det_gt_classes)
    det_gt_country(i)=country_map(det_gt_classes(i));
    det_pred_country(i)=country_map(det_pred_classes(i));
  end
  acc_country=mean(det_gt_country == det_pred_country)
  all_country=country_map.values;
  all_country=unique([all_country{:}]);
  country_names=cell(numel(all_country),1);
  for s=1:numel(all_country)
    country_names{s}=country_names_map(all_country(s));
  end

  plot_fg_results(det_gt_country,det_pred_country,'country',country_names,all_country',acc_country);
end

%Aggregate by model and do tests
if options.test_model
  model_map = class_to_modelid_map();
  model_names_map=model_class_to_modelname_map();
  for i=1:numel(det_gt_classes)
    det_gt_model(i)=model_map(det_gt_classes(i));
    det_pred_model(i)=model_map(det_pred_classes(i));
  end
  acc_model=mean(det_gt_model == det_pred_model)
  all_model=model_map.values;
  all_model=unique([all_model{:}]);
  model_names=cell(numel(all_model),1);
  for s=1:numel(all_model)
    model_names{s}=model_names_map(all_model(s));
  end

  plot_fg_results(det_gt_model,det_pred_model,'model',model_names,all_model',acc_model);
end
%Aggregate by year
%Aggregate by hybrid/non-hybrid

%Find out percentage of different types of mistakes 

if options.test_components
  %Wrong make
  wrong_make=1-acc_make

  %right make,wrong model
  wrong_model=mean((det_gt_makes==det_pred_makes) & (det_gt_model ~= det_pred_model))

  %right make,right model,wrong submodel
  wrong_submodel=mean((det_gt_makes==det_pred_makes) & (det_gt_model == det_pred_model) & (det_gt_submodels ~= det_pred_submodels))

  %right make,model,submodel, wrong trim/year
  %{
  wrong_trim_year=mean((det_gt_makes==det_pred_makes) & (det_gt_model == det_pred_model) & ...
                    (det_gt_submodels == det_pred_submodels) & (det_gt_classes' ~= det_pred_classes'))

  %wrong submodel,wrong make
  wrong_make_and_submodel=mean((det_gt_makes ~= det_pred_makes) & (det_gt_submodels ~= det_pred_submodels));

  err=1-acc;

  figure,
  keyboard
  bar((1/err).*[wrong_make,wrong_model,wrong_submodel,wrong_trim_year,wrong_make_and_submodel]);
  xticklabels={'wrong make','wrong model','wrong submodel', 'wrong trim/year', 'wrong make and submodel'};
  xticks=linspace(1,numel(xticklabels),numel(xticklabels));
  set(gca,'XTick',xticks,'XtickLabel',xticklabels);
  xticklabel_rotate([],75,[], 'Fontsize', 12)
  title('Percentage of mistakes')
  grid on
  %}
end

if options.experiment_with_bins
  %% If we knew the make how much would accuracy increase by
  [det_pred_probs_m,det_pred_classes_m,acc_know_make,ac5_know_make]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,make_map,0);

  %% If we knew the country?
  [det_pred_probs_c,det_pred_classes_c,acc_know_country,ac5_know_country]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,country_map,0);

  %% If we knew domestic/foreign?
  [det_pred_probs_df,det_pred_classes_df,acc_know_df,ac5_know_df]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,foreign_map,0);

  %% If we knew the submodel
  [det_pred_probs_s,det_pred_classes_s,acc_know_sub,ac5_know_sub]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,submodel_map,0);

  %% If we knew price
  [det_pred_probs_s,det_pred_classes_s,acc_know_price,ac5_know_price]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,price_map,1);


  %If we knew the price within 3 bins
  [det_pred_probs_s3,det_pred_classes_s3,acc_know_price3,ac5_know_price3]...
    =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,price_map,1);

  [acc_know_make,acc_know_country,acc_know_df,acc_know_sub,acc_know_price,acc_know_price3]
  [ac5_know_make,ac5_know_country,ac5_know_df,ac5_know_sub,ac5_know_price,ac5_know_price3]
  keyboard;

  %Accuracy by price bin & delta price bin
  price_bins=[2,4,8,10,15,20];
  delta_bins=[0,1,2,3,4];
  acc_know_price_m=zeros(numel(price_bins,1),numel(delta_bins));
  ac5_know_price_m=zeros(numel(price_bins,1),numel(delta_bins));

  for i=1:numel(price_bins)
    fprintf('price bin %d out of %d\n',i,numel(price_bins))
    price_map_n=class_to_priceid_map(price_bins(i));
    for j=1:numel(delta_bins)
      fprintf('delta bin %d out of %d\n',j,numel(delta_bins))
      [det_pred_probs_s,det_pred_classes_s,acc_know_price_m(i,j),ac5_know_price_m(i,j)]...
      =recalculate_probs(det_pred_classes,det_pred_probs,det_gt_classes,price_map_n,delta_bins(j));
    end
  end
  save('price_bin_acc.mat','acc_know_price_m','ac5_know_price_m')

  options.plot_price_acc=true;
  cmap = hsv(numel(price_bins));
  if options.plot_price_acc
    figure,
    title(sprintf('Price bin acc vs. price bin delta'));
    for i=1:numel(price_bins)
      p(i)=plot(delta_bins,acc_know_price_m(i,:),'Color',cmap(i,:));
      hold on 
      xlabel('delta bin')
      ylabel('accuracy')
    end
    legends=mat2cell(price_bins); 
    lh=legend(p,legends{:});
  end
end
