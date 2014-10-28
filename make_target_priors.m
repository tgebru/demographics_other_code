% Figure out the source prior

train_fname = 'gsv_train.mat';
out_fname = 'target_prior.mat';

% Extract classes
num_classes = 2657;
class_counts = zeros(1, num_classes);
load(train_fname);
for i = 1:numel(images)
  im_classes = images(i).classes;
  for j = 1:numel(im_classes)
    if im_classes(j) ~= -1
      class_counts(im_classes(j)+1) = class_counts(im_classes(j)+1) + 1;
    end
  end
end

% BDE prior,ish
class_counts = class_counts + 1;

probs = class_counts / sum(class_counts);
classes = 0:num_classes-1;
prob_map = containers.Map(classes, probs);
save(out_fname, 'probs', 'prob_map');
