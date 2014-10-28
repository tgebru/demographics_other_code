function [bboxes, pred_classes, im_nums] = sort_pred_bboxes(pred_bboxes, pred_classes)

num_pred_boxes = sum(cellfun(@(x)size(x, 1), pred_bboxes));
bboxes = zeros(num_pred_boxes, 4);
im_nums = zeros(num_pred_boxes, 1);


bboxes = vertcat(pred_bboxes{:});
pred_classes = vertcat(pred_classes{:});
assert(size(bboxes, 1) == size(pred_classes, 1));
im_nums = zeros(size(bboxes, 1), 1);

% Concatenate them
bbox_ind = 1;
for im_ind = 1:numel(pred_bboxes)
  im_nums(bbox_ind:bbox_ind+size(pred_bboxes{im_ind}, 1)-1) = im_ind;
  bbox_ind = bbox_ind + size(pred_bboxes{im_ind});
end

% Sort
[~, inds] = sort(bboxes(:, end), 'descend');
bboxes = bboxes(inds, :);
pred_classes = pred_classes(inds, :);
im_nums = im_nums(inds);

