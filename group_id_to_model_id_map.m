function map=group_id_to_model_id_map()
fdata = textscan(fopen('group_id_models.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
group_ids = double(fdata{1});
[~, model_ids] = ismember(fdata{2}, unique(fdata{2}));
map = containers.Map(group_ids, model_ids);
