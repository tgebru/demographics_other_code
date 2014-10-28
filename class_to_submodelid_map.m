function map = class_to_submodelid_map()
ctg = class_to_group_map();
gts = group_id_to_submodel_id_map();
map = containers.Map('keytype', 'double', 'valuetype', 'double');
classlist = ctg.keys;
for i = 1:numel(classlist)
  map(classlist{i}) = gts(ctg(classlist{i}));
end
