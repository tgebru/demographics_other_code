function map=group_id_to_foreign_id_map()
fdata=textscan(fopen('group_foreign.txt','r'),'%d\t%d\n','delimiter',{'\t'});
group_ids=double(fdata{1});
foreign_ids=double(fdata{2});
map=containers.Map(group_ids,foreign_ids);
