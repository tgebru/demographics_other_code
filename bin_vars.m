function [numels,edges,bins]=bin_vars(vars,num_bins)
quantiles=linspace(0,1,num_bins+1);
edges=unique(quantile(vars,quantiles));
[numels,bins]=histc(vars,[edges(1:end-1),edges(end)+1]);
