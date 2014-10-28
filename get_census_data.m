function census=get_census_data(im_name,conn,census_vars)
  [lat,lng]=get_lat_lng(im_name);
  fips_sql=sprintf('select fpis from demo.latlong_fpis where lat=%s and lng=%s',lat{:},lng{:});
  fips=get(fetch(exec(conn,fips_sql)),'Data');
  fips=num2str(fips{:});

  sqls=sprintf('select %s from demo.zipcode_acs where fips=%s',census_vars{:},fips); 
  census=get(fetch(exec(conn,sqls)),'Data');
  if ischar(census{1})
    census=-1;
  else
    census=[census{:}];
  end

