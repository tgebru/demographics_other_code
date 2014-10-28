function map = class_to_priceid_map(num_bins)
ctg = class_to_group_map();
gts = group_id_to_price_id_map();
map_nobin = containers.Map('keytype', 'double', 'valuetype', 'double');
classlist = ctg.keys;
for i = 1:numel(classlist)
  map_nobin(classlist{i}) = gts(ctg(classlist{i}));
end

%Bin price to have equal distribution accross classes
gsv_classes=csvread('gsv_train_data.txt');
no_gsv_classes=setdiff(cell2mat(map_nobin.keys()),unique(gsv_classes(:,1)));

all_prices=zeros(sum(gsv_classes(:,2))+numel(no_gsv_classes),1);
price_inds=zeros(size(gsv_classes,1)+numel(no_gsv_classes),1);

j=1;
for i=1:size(gsv_classes,1)
  price_inds(i)=j;
  all_prices(j:j+gsv_classes(i,2)-1)=map_nobin(gsv_classes(i));
  j=j+gsv_classes(i,2);
end

for k=1:numel(no_gsv_classes)
  all_prices(j+k-1)=map_nobin(no_gsv_classes(k));
  price_inds(i+k)=j+k-1;
end

quantiles=linspace(0,1,num_bins+1);
price_edges=unique(quantile(all_prices,quantiles));
[numels,price_ids]=histc(all_prices,[price_edges(1:end-1),price_edges(end)+1]);

map=containers.Map([gsv_classes(:,1);no_gsv_classes'],price_ids(price_inds));
