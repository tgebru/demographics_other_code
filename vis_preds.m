function vis_preds(im, bboxes, preds, thr)

cwidth = 2;
c = 'r';
s = '-';
if nargin <= 3
  thr = -20;
end

image(im); 
axis image;
axis off;
set(gcf, 'Color', 'white');

% Check for no detections
if isempty(bboxes)
  return
end

keep_mask = bboxes(:, end) > thr;
bboxes = bboxes(keep_mask, :);
preds = preds(keep_mask,:);
name_map = class_to_name_map();

for i = 1:size(bboxes,1)
  x1 = bboxes(i,1);
  y1 = bboxes(i,2);
  x2 = bboxes(i,3);
  y2 = bboxes(i,4);
  line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, 'linewidth', cwidth, 'linestyle', s);
  name = 'NOCLASS';
  if name_map.isKey(preds(i, 1))
    name = name_map(preds(i, 1));
  end
  text(x1+5,y1+5,sprintf('%s (%.2f, %.2f)',name,bboxes(i,5),preds(i,2)), 'Color', 'r');
end

