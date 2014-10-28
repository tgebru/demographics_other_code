% Takes bboxes with good class labels from GSV and saves them in caffe format
% (cropped, resized).


old_dir = '/data/jkrause/car_dataset';
bbox_fname = 'bboxes.txt';
new_dir = '/data/jkrause/cropped_resized_web_det/';

ov_data = load('overlaps.mat');
ov_centers = ov_data.ov_centers;
ov_probs = ov_data.ov_probs;

target_ar = 11/7; % Based on the dpm model
rand('seed', 0);

bbox_text = textscan(fopen(fullfile(old_dir, bbox_fname), 'r'), '%s\t%s');
rel_fnames = bbox_text{1};
bbox_strs = bbox_text{2};

for i = 1:numel(rel_fnames)
  fprintf('%d/%d\n', i, numel(rel_fnames));
  bbox_str = bbox_strs{i};
  im = imread(fullfile(old_dir, rel_fnames{i}));

  bbox_str = regexp(bbox_str, ',', 'split');
  gt_x1 = str2num(bbox_str{1});
  gt_y1 = str2num(bbox_str{2});
  gt_x2 = str2num(bbox_str{3});
  gt_y2 = str2num(bbox_str{4});

  % Sample some boxes
  samples = cell(size(ov_probs));
  samples = zeros(size(ov_probs));
  tic;
  new_fname = fullfile(new_dir, rel_fnames{i});
  [pardir, base, ext] = fileparts(new_fname);
  if ~exist(pardir, 'dir')
    mkdir(pardir);
  end
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
      bbgt = [gt_x1 gt_y1 gt_x2 gt_y2];
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
% TODO: the caffe .txt file itself
