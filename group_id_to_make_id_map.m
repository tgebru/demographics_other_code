function map = group_id_to_make_id_map()
fdata = textscan(fopen('group_make.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
group_ids = double(fdata{1});
[~, make_ids] = ismember(fdata{2}, unique(fdata{2}));
map = containers.Map(group_ids, make_ids);
