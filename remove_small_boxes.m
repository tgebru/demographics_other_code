function box_data = remove_small_boxes(box_data, options,set_threshold)
% options has the field bbox_min_dim

for i = 1:numel(box_data)
  bboxes = box_data(i).bboxes;
  % Either get the mask or generate it
  if isempty(bboxes)
    continue;
  end
  if isfield(box_data, 'big_enough')
    keep_mask = logical(box_data(i).big_enough);
  else
    keep_mask = ((bboxes(:, 3) - bboxes(:, 1) + 1) >= options.bbox_min_dim) & ...
                ((bboxes(: ,4) - bboxes(:, 2) + 1) >= options.bbox_min_dim);
  end
  if set_threshold
    preds=box_data(i).preds;
    keep_mask=keep_mask' & preds(:,1)~=-1;
    %keep_mask=keep_mask & bboxes(:,6)>=options.threshold;
  end

  % Filter out the fields.
  box_data(i).bboxes = box_data(i).bboxes(keep_mask, :);
  if isfield(box_data, 'group_ids')
    box_data(i).group_ids = box_data(i).group_ids(keep_mask);
  end
  if isfield(box_data, 'preds')
    box_data(i).preds = box_data(i).preds(keep_mask, :);
  end
  if isfield(box_data, 'classes')
    box_data(i).classes = box_data(i).classes(keep_mask);
  end
  if isfield(box_data, 'big_enough')
    box_data(i).big_enough = box_data(i).big_enough(keep_mask);
  end
end
