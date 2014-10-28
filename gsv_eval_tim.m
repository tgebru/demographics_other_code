function [ap, acc, num_fg_eval] = gsv_eval_tim(gt_data, pred_bboxes,pred_classes,bbox_im_nums,options)
% gt_data: im_fname, bboxes, group_ids, classes, big_enough
% both arguments have fields bboxes
% pred_data also has preds
minoverlap = 0.5;
%assert(numel(gt_data) == numel(pred_data));
num_ims = numel(gt_data);

% Remove boxes which are too small.
gt_data = remove_small_boxes(gt_data,options,0);
[pred_bboxes,pred_classes,bbox_im_nums] = remove_small_boxes_tim(pred_bboxes,pred_classes,bbox_im_nums,options,1);

gt_bboxes = arrayfun(@(x)x.bboxes, gt_data, 'uniformoutput', false);
gt_classes = arrayfun(@(x)x.classes, gt_data, 'uniformoutput', false);
num_gt_boxes = sum(cellfun(@(x)size(x, 1), gt_bboxes));

num_pred_boxes = size(pred_bboxes,1);
[all_pred_bboxes, all_pred_classes, im_nums] = sort_pred_bboxes_tim(pred_bboxes, pred_classes,bbox_im_nums);

tp=zeros(num_pred_boxes,1);
fp=zeros(num_pred_boxes,1);

det_gt_classes = zeros(num_gt_boxes, 1); % Overallocate
det_pred_classes = zeros(num_gt_boxes, 1);
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
        det_pred_classes(det_pred_ind) = all_pred_classes(pred_ind);
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
det_pred_classes = det_pred_classes(1:det_pred_ind-1);
num_fg_eval = numel(det_pred_classes);
if num_fg_eval > 0
  acc = mean(det_gt_classes == det_pred_classes);
else
  acc = 0;
end

name_map = class_to_name_map();
for i = 1:numel(det_gt_classes)
  fprintf('\npred: %s\ngt: %s\n', name_map(det_pred_classes(i)), name_map(det_gt_classes(i)));
end

%Plot images of predictions
for i = 1:numel(gt_data)
  fprintf('Image %d\n', i);
  fprintf('GT\n');
  im = imread(fullfile('/data/jkrause/gsv_100k_unwarp', gt_data(i).im_fname));
  vis_preds(im, horzcat(gt_data(i).bboxes, ones(size(gt_data(i).bboxes, 1), 1)), horzcat(gt_data(i).classes(:), ones(numel(gt_data(i).classes), 1)));
  keyboard;
  fprintf('pred\n');
  vis_preds(im, pred_data(i).bboxes, pred_data(i).preds);
  keyboard;
end

rec=tp/npos;
prec=tp./(fp+tp);
ap=VOCap(rec,prec);
