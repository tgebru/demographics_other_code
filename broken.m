function isBroken=broken(city_file,options)
  isBroken=exist(fullfile(options.broken_dir_root,city_file));
