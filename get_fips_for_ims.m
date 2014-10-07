function images=get_fips_for_ims(images)
  dbname='demo';
  username='tgebru';
  password='';
  driver='com.mysql.jdbc.Driver';
  dburl = ['jdbc:mysql://localhost:3306/' dbname];
  javaclasspath('/imagenetdb/tgebru/cars/demographics/boston_cars/code/mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');
  conn = database(dbname, username, password, driver, dburl);
  num_ims=length(images);
  for i=1:num_ims
    fprintf('getting fips for im #%d\n',i);
    splits=regexp(images(i).im_fname,'_','split');
    lat=splits(2);
    lng=splits(3);
    fips_query=sprintf('select fpis from demo.latlong_fpis d where d.lat=%s and d.lng=%s',lat{:},lng{:});
    fips=get(fetch(exec(conn,fips_query)),'Data');
    images(i).fips=num2str(fips{:});
  end


