function map=foreign_class_to_foreignname_map()
fdata = textscan(fopen('foreign_name.txt', 'r'), '%d\t%s\n', 'delimiter', {','});
price_ids = double(fdata{1});
map = containers.Map(double(fdata{1}),fdata{2});
