function map=group_id_to_price_id_map()
%fdata=textscan(fopen('group_tgprice.txt','r'),'%d\t%d\n','delimiter',{','});
%fdata=textscan(fopen('group_price.txt','r'),'%d\t%d\n','delimiter',{'\t'});
%fdata=textscan(fopen('group_course_price.txt','r'),'%d\t%d\n','delimiter',{'\t'});

fdata=textscan(fopen('group_price_actual.txt','r'),'%d\t%d\n','delimiter',{'\t'});
group_ids=double(fdata{1});
price_values=double(fdata{2});
map=containers.Map(group_ids,price_values);

