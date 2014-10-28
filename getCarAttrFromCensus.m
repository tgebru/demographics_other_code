% input_census is a m * 31 census matrix
% input_edges is a edge vector
% output_attr is 'price' but it is useless for now

function [pihat] = getCarAttrFromCensus (input_census, input_edges, output_attr)

load('data/train_5_data.mat')

train_thres_census_data = selectCensus(train_thres_census_data);


getResult = 0;


if getResult == 0
 
    [N,binPrice]=histc(train_thres_cars_data(:, 3),[input_edges(1:end-1),input_edges(end)+1]);
    
    input_census = selectCensus(input_census);

    %%Added by timnit
    zero_bins=find(binPrice==0); 
    binPrice(find(train_thres_cars_data(:,3)>max(input_edges)))...
     =max(binPrice);
    binPrice(find(train_thres_cars_data(:,3)<min(input_edges)))=1;
    %%
    B = mnrfit(train_thres_census_data, binPrice);
    
    
    pihat = mnrval(B, input_census);
    
    
%     returnProb = zeros(size(pihat, 1), length(input_edges) - 1);
%     
%     [maxValue, val_predict] = max(pihat,[],  2);
%     
%     for i = 1:size(pihat, 1)
%         for j = 1:length(input_edges) -1
%         meanValue = (edges(val_predict(i)) +  edges(val_predict(i) + 1)) / 2 ;
%         varValue = 7000;
%         returnProb(i, j) = sum(normpdf(input_edges(j) : 1 : input_edges(j + 1), meanValue, varValue)) / sum(normpdf(input_edges(1) : 1 : input_edges(end), meanValue, varValue));
%         end
%     end

    


elseif getResult == 1
    
    num_bins = 5;
    load('data/val_5_data.mat')
    val_thres_census_data = selectCensus(val_thres_census_data);
    
    quantiles=linspace(0,1,num_bins+1);
    edges=unique(quantile(train_thres_cars_data(:, 3) ,quantiles));
    [N,binPrice]=histc(train_thres_cars_data(:, 3),[edges(1:end-1),edges(end)+1]);
   % [N,binPrice]=histc(train_thres_cars_data(:, 3),[0 3000 6000 9000 12000 10000000 ]);
  

    B = mnrfit(train_thres_census_data, binPrice);
    
    
    pihat = mnrval(B, val_thres_census_data);
    
   
    [N, val_binPrice] = histc(val_thres_cars_data(:, 3),[edges(1:end-1),edges(end)+1]);
   % [N, val_binPrice] = histc(val_thres_cars_data(:, 3),[0 3000 6000 9000 12000 10000000 ]);
   
%    
%     accuracy = zeros(num_bins, 1);
%     for i = 1:num_bins
%         [maxValue, val_predict] = max(pihat,[],  2);
%         maxValue = repmat(maxValue, 1, num_bins);
%         for j = 1:length(val_binPrice)
%             pihat(j, val_predict(j)) = -1;
%         end
%         if i == 1
%             accuracy(i) = sum(val_predict == val_binPrice) / length(val_binPrice);
%         else
%             accuracy(i) = accuracy(i-1) + sum(val_predict == val_binPrice) / length(val_binPrice);
%         end
% 
%     end
% 
%     accuracy
% 
%     [maxValue, val_predict] = max(pihat,[],  2);
%     prob = 0;
%     for i = 1:size(pihat, 1)
%         meanValue = (edges(val_predict(i)) +  edges(val_predict(i) + 1)) / 2 ;
%         varValue = 7000;
%          prob = prob + sum(normpdf(val_edges(val_binPrice(i)):1:val_edges(val_binPrice(i) + 1), meanValue, varValue)) / sum(normpdf(val_edges(1):1:val_edges(num_bins_val + 1), meanValue, varValue));
%     end
%     prob = prob / size(pihat, 1)
        
%         
%     prob = 0;
%     for i = 1:size(pihat, 1)
%         prob = prob + pihat(i, val_binPrice(i));
%     end
%     prob = prob / size(pihat, 1)

end
%end
