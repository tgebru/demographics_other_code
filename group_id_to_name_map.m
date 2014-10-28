function map = group_id_to_name_map()
fdata = textscan(fopen('/data/jkrause/cropped_resized/group_names.txt', 'r'), '%d%s\n', 'delimiter', {'\t'});
map = containers.Map(double(fdata{1}), fdata{2});
