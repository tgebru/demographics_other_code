function [r,p,rb,pb,cmat]=visualize_relation(var1_bin,var2_bin,var1,var2,...,
  var1_name,var2_name,nb_var1,nb_var2,save_path,options)

  h=figure;
  subplot(2,1,1)
  cmat=confusionmat(var1_bin,var2_bin); 
  for i=1:size(cmat,2)
    cmat(:,i)=cmat(:,i)./sum(cmat(:,i));
  end
  [rb,pb]=corr(var1_bin,var2_bin,'type','spearman');
  [r,p]=corr(var1,var2,'type','spearman');

  if options.draw_figure
    imagesc(cmat);
 
    xlabel('census')
    ylabel('car')
    title(sprintf('training data with binning %d %d %d %d\n',var1_name,var2_name,nb_var1,nb_var2))
    subplot(2,1,2)
    plot(var1,var2,'*')
    title(sprintf('training data with no binning r=%f,p=%f,bin_r=%f,bin_p=%f',r,p,rb,pb))
    xlabel('census atts')
    ylabel('car atts')
  end
 
  save(fullfile(save_path,'figs'),'cmat','var1','var2','var1_bin','var2_bin');
