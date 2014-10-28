function map=price_class_to_pricename_map()

%fdata = textscan(fopen('price_name.txt', 'r'), '%d\t%s\n', 'delimiter', {','});
%fdata = textscan(fopen('fine_price_name.txt', 'r'), '%d\t%s\n', 'delimiter', {','});
fdata = textscan(fopen('course_price_name.txt', 'r'), '%d\t%s\n', 'delimiter', {','});
price_ids = double(fdata{1});
map = containers.Map(double(fdata{1}),fdata{2});
