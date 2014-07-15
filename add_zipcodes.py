import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
db=connect_to_db('demo')
cursor=db.cursor()
import logging

logging.basicConfig(filename='log.log',level=logging.DEBUG)
'''
fips_sql='select distinct(fpis) from latlong_fpis where fpis like "25%"'
cursor.execute(fips_sql)
fips=cursor.fetchall()
for f in fips:
  f=str(f[0])
  sql_s='select distinct zcta5 from ma_summary_file_1_geo_table where state=%s and county=%s and tract=%s and block=%s'%(f[0:2],f[2:5],f[5:11],f[11:15])
  print sql_s
  cursor.execute(sql_s)
  zipcode=cursor.fetchone()
  print zipcode[0]
  insert_s='update latlongs_fips set zipcode=%s where fips=%s'%(zipcode[0],f)
  print insert_s
  #cursor.execute(insert_s)

#Add fpis,place,zipcode,name,muni_id columns to ma_detected_cars
sql_s='alter table boston_cars.ma_detected_cars add column fpis int(15),add column place int(5),add column zipcode int(5), add column name varchar(100),add column muni_id int(3)'
print sql_s
cursor.execute(sql_s)

#add fpis
sql_s='update boston_cars.ma_detected_cars m,demo.latlong_fpis l set m.fpis=l.fpis where m.lat=l.lat and m.lng=l.lng'
cursor.execute(sql_s)
sql_s='update boston_cars.ma_detected_cars d,demo.latlong_fpis l set d.zipcode=l.zipcode where d.fpis=l.fpis'
cursor.execute(sql_s)
'''

#for all the latlongs in ma_detected table, add zipcode,fpis code,place code,place name,muni_id
sql_s='select distinct(fpis) from boston_cars.ma_detected_cars'
cursor.execute(sql_s)
fpis=cursor.fetchall()
i=0
tot_num=len(fpis)
for f in fpis:
  i +=1 
  f=str(f[0])
  print f
  sql_s='select distinct(place)from ma_summary_file_1_geo_table where state=%s and county=%s and tract=%s and block=%s'%(f[0:2],f[2:5],f[5:11],f[11:15])
  print sql_s
  cursor.execute(sql_s)
  place_code=cursor.fetchone()[0]
  print place_code
  sql_s='select distinct(name) from demo.ma_summary_file_1_geo_table where (name like "%%city%%" or name like "%%town%%") and place=%s'%place_code
  print sql_s
  cursor.execute(sql_s)
  place_names=cursor.fetchall()
  place_name=''
  if len(place_names)==1:
    place_name=place_names[0].strip()
  else:
    for p in place_names:
      if 'part' not in p[0]:
        place_name=p[0].strip()
      

  #Get muni_id using MA ground truth data
  municipal=place_name.replace('town','').replace('city','')
  sql_s='select distinct(muni_id) from boston_cars.grid250m_attributes where municipal="%s"'%municipal
  cursor.execute(sql_s)
  muni_id=cursor.fetchall()
  if len(muni_id)==1:
    muni_id=muni_id[0][0]
    print muni_id
    sql_s='update boston_cars.ma_detected_cars set name="%s",muni_id=%d,place=%s where fpis=%s'%(place_name,muni_id,place_code,f)  
    print sql_s
    cursor.execute(sql_s)
  else:
    print 'error too many munis for place %s'%place_code
    logging.debug('error too many munis for place %s'%place_code)
  print '....processed %d out of %d...'%(i,tot_num)
 
  
   
