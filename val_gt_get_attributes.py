import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import scipy.io
import numpy
import os

if __name__=="__main__":
  census_or_acs= sys.argv[1] #'acs'
  LEVEL= sys.argv[2] #'zipcode'
  train_or_val=sys.argv[3]

  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()
  root_dir='/imagenetdb3/mysql_tmp_dir/car_census'

  census_var_name_f='%s_var_names.txt'%census_or_acs
  census_variables_f='%s_%s_variables.txt'%(train_or_val,census_or_acs)

  car_meta_name_f='car_meta_names.txt'
  car_attributes_f='%s_car_attributes.txt'%(train_or_val)

  census_var_file_name='%s_variables.txt'%census_or_acs
  census_vars=open(census_var_file_name).readlines()
  census_variables=[]
  i=0
  for c in census_vars:
    census_variables.insert(i,c.split(',')[0].strip())
    i += 1
    
  census_variables=','.join(census_variables)
  print census_variables
  with open(census_var_name_f,'w') as f:
    f.write('%s\n'%census_variables)

  #Get Car attributes
  att_name_query="select column_name from information_schema.columns where table_name='car_metadata' and (column_name='price' or column_name='fine_price_bracket')"
  print att_name_query
  cursor.execute(att_name_query)
  car_att_names=cursor.fetchall()
  car_att_names=[l[0] for l in car_att_names]
  car_att_names=','.join(car_att_names)
  with open(car_meta_name_f,'w') as f:
    f.write('%s\n'%car_att_names)

  #get car attributes
  car_attr_query='select group_id,%s from all_cars.%s_gt_detected_cars join geocars.car_metadata using(group_id)'%(car_att_names,train_or_val)
  cursor.execute(car_attr_query)
  car_att_vals=cursor.fetchall()

  with open(car_attributes_f,'w') as f: 
    for a in car_att_vals:
      print a
      f.write('%s\n'%','.join([str(l)for l in a]))

  #Get census data
  im_namesq='select group_id,im_name from all_cars.%s_gt_detected_cars where group_id<>-1'%train_or_val

  cursor.execute(im_namesq)
  im_names=cursor.fetchall()
    
  f=open(census_variables_f,'w')
  i=0
  num_ims=len(im_names)
  for im in im_names:
    i += 1
    print '%d out of %d\n'%(i,num_ims)
    lat=im[1].split('_')[1]
    lng=im[1].split('_')[2]

    census_query='select %s from demo.latlong_fpis f, demo.%s_%s t  where f.lat=%s and f.lng=%s and f.fpis=t.fips'%(census_variables,LEVEL,census_or_acs,lat,lng)
    print census_query
    cursor.execute(census_query)
    vars=cursor.fetchall()
    if vars:
      vars_str=','.join([str(v) for v in vars[0]])
      vars_str=vars_str.replace('None','-1')
      f_str='%s,%s\n'%(im[0],vars_str)
      print f_str
      f.write(f_str)
    else:
      sys.stderr.write('%s,%s no census data\n'%(lat,lng))
