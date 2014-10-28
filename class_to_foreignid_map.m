 function map=class_to_foreignid_map()
ctg = class_to_group_map();
gtm = group_id_to_foreign_id_map();
map = containers.Map('keytype', 'double', 'valuetype', 'double');
classlist = ctg.keys;
for i = 1:numel(classlist)
  map(classlist{i}) = gtm(ctg(classlist{i}));
end
