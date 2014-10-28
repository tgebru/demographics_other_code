function map=groupid_to_countryname_map()
fdata=textscan(fopen('group_country.txt','r'),'%d\t%s\n','delimiter',{'\t'});
map=containers.Map(fdata{1},fdata{2});
