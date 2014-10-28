% Figure out the source prior

train_fname = '/home/jkrause/gsv_classify/webgsv_det_train.txt';
out_fname = 'source_prior.mat';

%in_data = textscan(fopen(train_fname, 'r'), '%s %d');
in_data = textscan(fopen(train_fname, 'r'), '%s %d %s');
classes = double(in_data{2});
[counts, classes] = hist(classes, unique(classes));

probs = counts / sum(counts);

prob_map = containers.Map(classes, probs);
assert(all(classes(:) == (0:max(classes))'));

save(out_fname, 'probs', 'prob_map');
