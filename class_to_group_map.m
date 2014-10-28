function map = class_to_group_map()
arr = csvread('big_group_map.txt');
map = containers.Map(double(arr(:, 1)), double(arr(:, 2)));
