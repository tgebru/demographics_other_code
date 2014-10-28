function map = group_id_to_submodel_id_map()
fdata = textscan(fopen('group_submodel.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
group_ids = double(fdata{1});
[~, submodel_ids] = ismember(fdata{2}, unique(fdata{2}));
map = containers.Map(group_ids, submodel_ids);
