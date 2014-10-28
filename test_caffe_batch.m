function [ftime,preds]=test_caffe_batch(input_data,options,num_output);

% init caffe network (spews logging info)
%Initialize caffe only if its not initialized
if (caffe('is_initialized') == 0)
  fprintf('initialize caffe\n');
  caffe('init', options.model_def_file, options.model_file);
  fprintf('initialized\n');

  % set to use GPU or CPU
  if options.use_gpu
    caffe('set_mode_gpu');
    caffe('set_device', options.gpu_num);
  else
    caffe('set_mode_cpu');
  end

  % put into test mode
  caffe('set_phase_test');
end

t=tic;
scores = caffe('forward', {input_data});
ftime=toc(t);
scores = reshape(scores{1}, options.num_classes, []);
[max_score, max_ind] = max(scores);
preds = [max_ind'-1,max_score']; % 0-indexed
if (num_output ~= options.batch_size)
  preds = preds(1:num_output,:);
end
