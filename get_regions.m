function images = get_regions(im, bbox, options)


  IMAGE_DIM = options.image_dim;
  CROPPED_DIM = options.cropped_dim;

  if options.skip_augmentation
    images = zeros(IMAGE_DIM, IMAGE_DIM, 3, num_ims, 'single');
    
  % TODO: Sample neighborhood/simulate that it's a detection
  num_bboxes = 1;
  bbox_ind = 1;
  sampled_bboxes = zeros(num_bboxes, 4);

  % Get sampled bboxes
  sampled_bboxes(bbox_ind, :) = bbox;
  bbox_ind = bbox_ind + 1;

  % Get bbox regions
  regions = cell(num_bboxes, 1);
  for i = 1:num_bboxes
    bbox = round(sampled_bboxes(i,:));
    % x1 y1 x2 y2
    x1 = bbox(1);
    y1 = bbox(2);
    x2 = bbox(3);
    y2 = bbox(4);
    regions{i} = single(imresize(im(y1:y2, x1:x2,:), options.resize_dims, ...
      'bilinear', 'antialiasing', false));
  end

  % Put in caffe format
  num_ims = num_bboxes * (1 * options.use_center + 4 * options.use_corners) * (1 + options.use_flips);

  persistent IMAGE_MEAN;
  if isempty(IMAGE_MEAN)
    d = load(options.mean_fname);
    IMAGE_MEAN = d.image_mean;
  end
  images = zeros(CROPPED_DIM, CROPPED_DIM, 3, num_ims, 'single');

  curr = 1;
  for k = 1:numel(regions)
    % permute from RGB to BGR (IMAGE_MEAN is already BGR)
    im = regions{k}(:,:,[3 2 1]) - IMAGE_MEAN;

    % oversample (4 corners, center, and their x-axis flips)
    indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
    if options.use_corners
      for i = indices
        for j = indices
          images(:, :, :, curr) = ...
              permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
          curr = curr + 1;
        end
      end
    end
    if options.use_center
      center = floor(indices(2) / 2)+1;
      images(:,:,:,curr) = ...
          permute(im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:), ...
              [2 1 3]);
      curr = curr + 1;
    end
  end
  if options.use_flips
    assert(curr == num_ims/2+1);
    images(:, :, :, curr:end) = images(end:-1:1, :, :, 1:(curr-1));
  end
end
