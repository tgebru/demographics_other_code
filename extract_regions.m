function regions = extract_regions(im, bboxes, resize_dims)

num_regions = size(bboxes, 1);
regions = cell(1, num_regions);
for i = 1:num_regions
  bbox = bboxes(i,:);
  % x1 y1 x2 y2
  x1 = round(bbox(1));
  y1 = round(bbox(2));
  x2 = round(bbox(3));
  y2 = round(bbox(4));
  window = im(y1:y2, x1:x2, :);
  region = imresize(window, resize_dims, 'bilinear', 'antialiasing', false);
  regions{i} = region;
end
