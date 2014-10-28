function [bboxes,classes,ims] = remove_small_boxes_tim(bboxes,classes,ims,options,set_threshold)
% options has the field bbox_min_dim

keep_mask = ((bboxes(:, 3) - bboxes(:, 1) + 1) >= options.bbox_min_dim) & ...
                ((bboxes(: ,4) - bboxes(:, 2) + 1) >= options.bbox_min_dim);

keyboard;
keep_mask=keep_mask&
if set_threshold
  keep_mask=bboxes(:,end)>=options.threshold
end

% Filter out the fields.
bboxes = bboxes(keep_mask, :);
classes = classes(keep_mask, :);
ims = ims(keep_mask, :);
