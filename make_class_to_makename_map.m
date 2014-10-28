function map=make_class_to_makename_map()
ctg = class_to_group_map();
make_map=class_to_makeid_map(); 
make_name_map=groupid_to_makename_map();

map=containers.Map('keytype','double','valuetype','char');
classlist=ctg.keys;
for i=1:numel(classlist)
   map(make_map(classlist{i}))=make_name_map(ctg(classlist{i}));
end
