function map=group_id_to_countryid_map()
fdata = textscan(fopen('group_country.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
group_ids = double(fdata{1});
[~, country_ids] = ismember(fdata{2}, unique(fdata{2}));

map = containers.Map(group_ids,country_ids);
