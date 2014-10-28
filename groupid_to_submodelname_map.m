function map = groupid_to_submodelname_map()
  fdata = textscan(fopen('group_submodel.txt', 'r'), '%d\t%s\n', 'delimiter', {'\t'});
  group_ids = double(fdata{1});
  map = containers.Map(double(fdata{1}),fdata{2});
