function map=submodel_class_to_submodelname_map()
ctg = class_to_group_map();
submodel_map=class_to_submodelid_map(); 
submodel_name_map=groupid_to_submodelname_map();

map=containers.Map('keytype','double','valuetype','char');
classlist=ctg.keys;
for i=1:numel(classlist)
   map(submodel_map(classlist{i}))=submodel_name_map(ctg(classlist{i}));
end
