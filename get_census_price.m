function [census_vars,price_vec]=get_census_price(input_ims,num_bins,num_census_vars)

%census_inds=[6,12,23,24];
%num_census_vars=numel(census_inds);
census_inds=1:num_census_vars;
census_vars=zeros(numel(input_ims),num_census_vars);
att_map=class_to_priceid_map(num_bins);

k=1;
price_vec=zeros(numel(input_ims),1);
for i=1:numel(input_ims)
  
  if(numel(input_ims(i).census)<num_census_vars)
    continue;
  end
  for j=1:numel(input_ims(i).classes) 
    if (input_ims(i).classes(j) ==-1)
      continue;
    end
    census_vars(k,:)=input_ims(i).census(census_inds);
    inds=find(isnan(census_vars(k,:)));
    census_vars(k,inds)=0;
    price_vec(k)=att_map(input_ims(i).classes(j));
    k=k+1;
  end
end

price_vec(k:end)=[];
census_vars(k:end,:)=[];


