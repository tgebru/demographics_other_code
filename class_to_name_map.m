function map = class_to_name_map()
ctg = class_to_group_map();
gtn = group_id_to_name_map();
map = containers.Map('keytype', 'double', 'valuetype', 'char');
classlist = ctg.keys;
for i = 1:numel(classlist)
  map(classlist{i}) = gtn(ctg(classlist{i}));
end
