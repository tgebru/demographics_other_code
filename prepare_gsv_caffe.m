% Takes bboxes with good class labels from GSV and saves them in caffe format
% (cropped, resized).


out_dir_base = '/data/jkrause/cropped_resized_gsv/';
im_dir = '/data/jkrause/gsv_100k_unwarp';


splits = {'train', 'test'};
for split_ind = 1:numel(splits);
  split_name = splits{split_ind};
  im_data = load(sprintf('gsv_%s.mat', split_name));
  images = im_data.images;
  out_dir_ims = fullfile(out_dir_base, split_name);
  if ~exist(out_dir_ims, 'dir')
    mkdir(out_dir_ims);
  end
  caffe_fname = fullfile(out_dir_base, sprintf('%s.txt', split_name));
  bbox_index = 0;
  caffe_fout = fopen(caffe_fname, 'w');
  for i = 1:numel(images)
    fprintf('%s im %d/%d\n', split_name, i, numel(images));
    im = [];
    for j = 1:numel(images(i).classes)
      if images(i).classes(j) ~= -1
        if isempty(im)
          im = imread(fullfile(im_dir, images(i).im_fname));
        end
        % Crop and resize
        x1 = images(i).bboxes(j,1);
        y1 = images(i).bboxes(j,2);
        x2 = images(i).bboxes(j,3);
        y2 = images(i).bboxes(j,4);
        cropped = im(y1:y2, x1:x2, :);
        resized = imresize(cropped, [256 256], 'bilinear');
        new_fname = fullfile(out_dir_ims, sprintf('%06d_%02d.jpg', i, j));
        imwrite(resized, new_fname);
        fprintf(caffe_fout, '%s %d\n', new_fname, images(i).classes(j));
      end
    end
  end
end
