% Takes bboxes with good class labels from GSV and saves them in caffe format
% (cropped, resized).


out_dir_base = '/data/jkrause/cropped_resized_gsv_det/';
im_dir = '/data/jkrause/gsv_100k_unwarp';

ov_data = load('overlaps.mat');
ov_centers = ov_data.ov_centers;
ov_probs = ov_data.ov_probs;

target_ar = 11/7; % Based on the dpm model
rand('seed', 0);

splits = {'train', 'val', 'test_noval'};
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
        gt_x1 = images(i).bboxes(j,1);
        gt_y1 = images(i).bboxes(j,2);
        gt_x2 = images(i).bboxes(j,3);
        gt_y2 = images(i).bboxes(j,4);

        % Sample some boxes
        samples = cell(size(ov_probs));
        samples = zeros(size(ov_probs));
        tic;
        for kk = 1:10
          new_fname = fullfile(out_dir_ims, sprintf('%06d_%02d_%02d.jpg', i, j, kk));
          fprintf(caffe_fout, '%s %d\n', new_fname, images(i).classes(j));
          if exist(new_fname, 'file')
            fprintf('already have\n');
            continue;
          end
          ok_sample = false;
          while ~ok_sample
            samplei = discretesample(ov_probs);
            tic;
            for k = 1:10000
              sample_w = (.5 + 1.0 * rand()) * (gt_x2 - gt_x1 + 1);
              sample_h = round(sample_w / target_ar);
              sample_w = round(sample_w);
              sample_x1 = max(1, round(gt_x1 + 1.0 * (.5 - rand()) * (gt_x2 - gt_x1 + 1)));
              sample_y1 = max(1, round(gt_y1 + 1.0 * (.5 - rand()) * (gt_y2 - gt_y1 + 1)));
              sample_x2 = sample_x1 + sample_w - 1;
              sample_y2 = sample_y1 + sample_h - 1;
              sample_x1 = min(max(sample_x1, 1), size(im, 2));
              sample_x2 = min(max(sample_x2, 1), size(im, 2));
              sample_y1 = min(max(sample_y1, 1), size(im, 1));
              sample_y2 = min(max(sample_y2, 1), size(im, 1));
              bb = [sample_x1 sample_y1 sample_x2 sample_y2];
              bbgt = images(i).bboxes(j,:);
              bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
              iw=bi(3)-bi(1)+1;
              ih=bi(4)-bi(2)+1;
              ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                iw*ih;
              ov = (iw>0 && ih>0) * iw*ih/ua;
              if ov > .5
                [~, mini] = min(abs(ov - ov_centers));
                if mini == samplei
                  ok_sample = true;
                  break;
                end
              end
            end
            toc;
            if ~ok_sample
              fprintf('bad sample\n');
              % Just keep the whole thing
              ok_sample = true;
              sample_x1 = min(max(gt_x1, 1), size(im, 2));
              sample_x2 = min(max(gt_x2, 1), size(im, 2));
              sample_y1 = min(max(gt_y1, 1), size(im, 1));
              sample_y2 = min(max(gt_y2, 1), size(im, 1));
            end
          end
          cropped = im(sample_y1:sample_y2, sample_x1:sample_x2, :);
          resized = imresize(cropped, [256 256], 'bilinear');
          imwrite(resized, new_fname);
        end
      end
    end
  end
end
