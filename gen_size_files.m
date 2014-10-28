load('bboxstats.mat');

% Save in log(area)-space

[counts, centers] = hist(gsv_bboxes(:, 4), 50);
probs = counts / sum(counts);

% Convert to resize dimensions.
centers = round(sqrt(exp(centers)));
big_ind = find(centers >= 256, 1);
centers(big_ind+1:end) = [];
probs(big_ind+1:end) = [];
probs(end) = 1 - sum(probs(1:end-1));

f = fopen('gsv_resize_probs.txt', 'w');
for i = 1:numel(probs)
  fprintf(f, '%d %f\n', centers(i), probs(i));
end
fclose(f);
