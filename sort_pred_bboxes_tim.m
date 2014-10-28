function [bboxes, pred_classes, ims] = sort_pred_bboxes(pred_bboxes, pred_classes,im_nums)

num_pred_boxes = size(pred_bboxes,1);
assert(size(pred_bboxes, 1) == size(pred_classes, 1));

% Sort
[~, inds] = sort(pred_bboxes(:, end), 'descend');
bboxes = pred_bboxes(inds, :);
pred_classes = pred_classes(inds, :);
ims = im_nums(inds);
