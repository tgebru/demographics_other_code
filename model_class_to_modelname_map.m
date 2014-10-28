function map=model_class_to_modelname_map()
ctg = class_to_group_map();
model_map=class_to_modelid_map(); 
model_name_map=groupid_to_modelname_map();

map=containers.Map('keytype','double','valuetype','char');
classlist=ctg.keys;
for i=1:numel(classlist)
   map(model_map(classlist{i}))=model_name_map(ctg(classlist{i}));
end
