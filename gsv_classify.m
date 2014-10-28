function [bboxes, preds] = gsv_classify(im, dpm_model, options)

persistent initialized;
if isempty(initialized)
  fprintf('initializing dpm\n');
  addpath(fullfile(pwd, 'voc-release5'));
  startup;
  initialized = true;
end


fprintf('run dpm\n');
bboxes = process(im, dpm_model, options.det_thresh);
num_bboxes = size(bboxes, 1);
preds = classify_bboxes(im, bboxes, options);

end
