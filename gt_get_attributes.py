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
  image_names_f='%s_image_names.txt'%(train_or_val)

  census_var_file_name='%s_variables.txt'%census_or_acs
  census_vars=open(census_var_file_name).readlines()
  census_variables=[]
  i=0
  for c in census_vars:
    census_variables.insert(i,c.split(',')[0].strip())
    i += 1
    
  census_variables=','.join(census_variables)
  with open(census_var_name_f,'w') as f:
    f.write('%s\n'%census_variables)

  car_att_names='price,make_id,submodel_id,country_id,is_foreign'
  with open(car_meta_name_f,'w') as f:
    f.write('%s\n'%car_att_names)

  #get car attributes and census_data
  car_atts=[]
  census_atts=[]
  ims_query='select distinct im_name from all_cars.%s_gt_detected_cars'%train_or_val

  cursor.execute(ims_query) 
  ims=cursor.fetchall()
  i=0
  num_ims=len(ims)
  num_census_vars=len(census_variables.split(','))
  all_ims=[]
  group_index=0;
  for im in ims:
    i += 1
    print '%d out of %d\n'%(i,num_ims)
    lat=im[0].split('_')[1]
    lng=im[0].split('_')[2]

    g_id_query='select im_name,group_id,%s from all_cars.%s_gt_detected_cars join geocars.car_metadata using(group_id) where im_name="%s" and group_id<>-1'%(car_att_names,train_or_val,im[0])
    cursor.execute(g_id_query)
    group_ids_car_atts=cursor.fetchall()
    if group_ids_car_atts:

      census_query='select %s from demo.latlong_fpis f, demo.%s_%s t  where f.lat=%s and f.lng=%s and f.fpis=t.fips'%(census_variables,LEVEL,census_or_acs,lat,lng)
      cursor.execute(census_query)
      vars=cursor.fetchall()
     
      for g in group_ids_car_atts: 
        car_atts.insert(group_index,(g[1:]))
        all_ims.insert(group_index,g[0])
        if vars:
          census_atts.insert(group_index,(g[1],)+vars[0])
        else:
          census_atts.insert(group_index,(g[1],)+(-1,)*num_census_vars) 
        group_index += 1
  
  
  with open(car_attributes_f,'w') as f: 
    for a in car_atts:
      #f.write('%s\n'%str(a).replace('(','').replace(')',''))
      f.write('%s\n'%','.join([str(l)for l in a]))

  with open(census_variables_f,'w') as f:
    for c in census_atts:
      #f.write('%s\n'%str(c).replace('(','').replace(')','').replace('None','-1'))
      f.write('%s\n'%(','.join([str(l) for l in c])).replace('None','-1'))

  with open(image_names_f,'w') as f:
    for im in all_ims:
      f.write('%s\n'%im)
