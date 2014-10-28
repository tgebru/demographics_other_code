function map=group_to_class()
  arr = csvread('big_group_map.txt');
  map = containers.Map(double(arr(:, 2)), double(arr(:, 1)));
