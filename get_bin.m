function bin=get_bin(var,edges)
  [numel,bin]=histc(var,[edges(1:end-1),edges(end)+1]);
