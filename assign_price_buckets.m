dbname='geocars';
username='tgebru';
password='';
driver='com.mysql.jdbc.Driver';
dburl = ['jdbc:mysql://localhost:3306/' dbname];
javaclasspath('/imagenetdb/tgebru/cars/demographics/boston_cars/code/mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');
conn = database(dbname, username, password, driver, dburl);
price_query='select price from geocars.car_metadata';

price_data=get(fetch(exec(conn,price_query)),'Data');
price=[price_data{:,1}];
close(conn)
hist(price,1000);
grid on;
title('Car Price')
q=quantile(price, [.2 .4 .6 .8]) 
[num_elems,bin_assignments]=histc(price,[0 q max(price)]+1);

%More granularity
qn=quantile(price, [.1 .2 .3 .4 .5 .6 .7 .8]) ;  
[n b]=histc(price, [0 qn max(price)+1]);

keyboard
fid1=fopen('price_quantile.txt','w');
fid2=fopen('fine_price_quantile.txt','w');

fprintf(fid1,'%d,%d\n',[price;bin_assignments]);
fprintf(fid2,'%d,%d\n',[price;b]);
