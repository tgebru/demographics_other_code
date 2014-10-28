function map=country_class_to_countryname_map()
ctg=class_to_group_map();
country_map=class_to_countryid_map(); 
country_name_map=groupid_to_countryname_map();

keyboard
map=containers.Map('keytype','double','valuetype','char');
classlist=ctg.keys;
for i=1:numel(classlist)
   map(country_map(classlist{i}))=country_name_map(ctg(classlist{i}));
end
