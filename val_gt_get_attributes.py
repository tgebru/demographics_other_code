import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import scipy.io
import numpy
import os

db_name='all_cars' 
db = connect_to_db(db_name)
cursor = db.cursor()
root_dir='/imagenetdb3/mysql_tmp_dir/car_census'

car_meta_name_f='car_meta_names.txt'
census_var_name_f='census_var_names.txt'
census_variables_f='val_census_variables.txt'
car_attributes_f='val_car_attributes.txt'

var_name_query="select column_name from information_schema.columns where table_name='tract_census' and column_name<>'tract' and column_name<>'id' and column_name<>'fips' and column_name<>'county' and column_name<>'state'"

cursor.execute(var_name_query)
census_variables=cursor.fetchall()
census_variables=[l[0] for l in census_variables]
  
census_variables=','.join(census_variables)
with open(census_var_name_f,'w') as f:
  f.write('%s\n'%census_variables)

att_name_query="select column_name from information_schema.columns where table_name='car_metadata' and (column_name='price' or column_name='fine_price_bracket')"
print att_name_query
cursor.execute(att_name_query)
car_att_names=cursor.fetchall()
car_att_names=[l[0] for l in car_att_names]
car_att_names=','.join(car_att_names)
with open(car_meta_name_f,'w') as f:
  f.write('%s\n'%car_att_names)

#get car attributes
car_attr_query='select group_id,%s from all_cars.gt_val_detected_cars join geocars.car_metadata using(group_id)'%car_att_names
cursor.execute(car_attr_query)
car_att_vals=cursor.fetchall()

with open(car_attributes_f,'w') as f: 
  for a in car_att_vals:
    print a
    f.write('%s\n'%','.join([str(l)for l in a]))

#Get census data
im_namesq='select group_id,im_name from all_cars.gt_val_detected_cars where group_id<>-1'

cursor.execute(im_namesq)
im_names=cursor.fetchall()
  
f=open(census_variables_f,'w')
for im in im_names:
  lat=im[1].split('_')[1]
  lng=im[1].split('_')[2]

  census_query='select %s from demo.latlong_fpis f, demo.tract_census t  where f.lat=%s and f.lng=%s and f.fpis=t.fips'%(census_variables,lat,lng)
  print census_query
  cursor.execute(census_query)
  vars=cursor.fetchall()
  if vars:
    vars_str=','.join([str(v) for v in vars[0]])
    f_str='%s,%s\n'%(im[0],vars_str)
    print f_str
    f.write(f_str)
  

