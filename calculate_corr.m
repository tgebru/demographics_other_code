function [r,p]= calculate_corr(a,b,x_name,y_name,y_exp,options)
  % remove zeros
  a_zeros=find(a==0 | a==-1);
  b_zeros=find(b==0 | b==-1);

  all_zeros=union(a_zeros,b_zeros);
  a_noz=a;
  b_noz=b;
  a_noz(all_zeros)=[];
  b_noz(all_zeros)=[];

  if (~isempty(a_noz) && ~isempty(b_noz))
      [r,p]=corr(a_noz,b_noz,'type',options.cor)
      figure,
      plot(a_noz,b_noz,'*')
      xlabel(x_name)
      ylabel(y_exp)
      title(sprintf('%s Correlation r=%f,p=%f',options.cor,r,p))
  else
      r=2;p=0
  end

%function info=calculate_info(a,b)

