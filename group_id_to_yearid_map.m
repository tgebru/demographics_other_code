function map=group_id_to_yearid_map()
fdata = textscan(fopen('group_year.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
group_ids = double(fdata{1});
[~, year_ids] = ismember(fdata{2}, unique(fdata{2}));

map = containers.Map(group_ids,year_ids);
