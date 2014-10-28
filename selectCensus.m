function [new_train_data] = selectCensus(train_data)

%all_data = [train_data ; val_data];

new_train_data = [train_data(:, 7) train_data(:, 12:12) train_data(:, 23:24) ];

% num_bins = 10;
% quantiles=linspace(0,1,num_bins+1);
% 
% for i = 1:size(new_train_data, 2)
%     edges=unique(quantile(new_train_data(:, i),quantiles));
%     [N,new_train_data(:, i)]=histc(new_train_data(:, i),[edges(1:end-1),edges(end)+1]);
%     
%     edges=unique(quantile(new_val_data(:, i),quantiles));
%     [N,new_val_data(:, i)]=histc(new_val_data(:, i),[edges(1:end-1),edges(end)+1]);
% end


% 
% new_train_data = [train_data(:, 12:14) train_data(:, 20:24) train_data(:, 29:30)];
% new_val_data = [val_data(:, 12:14) val_data(:, 20:24) val_data(:, 29:30)];
end