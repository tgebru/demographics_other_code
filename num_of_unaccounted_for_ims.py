import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
db=connect_to_db('boston_cars')
cursor=db.cursor()
import pickle

#Number of All images
sql_s='select count(distinct(im_name)) from ma_detected_cars'
print sql_s
cursor.execute(sql_s)
num_ims=cursor.fetchall()
print 'number of sampled images in MA....'
print num_ims

#Number of images per zipcode
zipcodes_sql='select distinct(zipcode),count(distinct(im_name))c from ma_detected_cars m,demo.latlong_fpis l where m.lat=l.lat and m.lng=l.lng group by zipcode order by c'
print zipcodes_sql
cursor.execute(zipcodes_sql)
zipcodes_num_ims=cursor.fetchall()
zip_dict={}
for z in zipcodes_num_ims:
  zip_dict[z[0]]=z[1]

print(zipcodes_num_ims)

#Number of all ground truth images in the 3 cities 
gt_sql='select distinct(zip_code),sum(veh_tot)s from grid250m_attributes a,grid_quarters_public g where a.g250m_id=g.g250m_id and quarter="2010_q2" and (muni_id=35 or muni_id=281 or muni_id=348) group by zip_code'

print gt_sql
cursor.execute(gt_sql)
gt_zipcodes_count=cursor.fetchall()
gt_zipcodes_dict={}
for g in gt_zipcodes_count:
  gt_zipcodes_dict[g[0]]=g[1]

print(gt_zipcodes_dict)

#Zipcodes in ground truth not in sampled data
gt_zipcodes=set(gt_zipcodes_dict.keys())
sampled_zipcodes=set(zip_dict.keys())
zip_not_sampled=gt_zipcodes-sampled_zipcodes

#Zipcodes in sampled data not in ground truth
zip_not_in_gt=sampled_zipcodes-gt_zipcodes

#number of images in these zipcodes
num_ims_not_sampled=0
num_ims_not_in_gt=0
for z in zip_not_sampled:
  num_ims_not_sampled += gt_zipcodes_dict[z]

print 'not sampled'
print(zip_not_sampled)

print 'not in gt' 
print (zip_not_in_gt)

print 'fraction of gt zipcodes not sampled'
print 100*float(len(zip_not_sampled))/len(gt_zipcodes)

print 'fraction of sampled zipcodes not in gt'
print 100*float(len(zip_not_in_gt))/len(sampled_zipcodes)

for z in zip_not_in_gt:
  num_ims_not_in_gt += zip_dict[z]

#Number of Total images in ground truth and in sampled zipcodes
num_tot_sampled_ims=sum(zip_dict.values())
num_tot_gt_ims=sum(gt_zipcodes_dict.values())

print num_tot_sampled_ims,num_tot_gt_ims

percent_not_in_gt=100*float(num_ims_not_in_gt)/num_tot_sampled_ims
percent_not_in_sampled=100*float(num_ims_not_sampled)/float(num_tot_gt_ims)

print percent_not_in_gt,percent_not_in_sampled

#Cities of the sampled zipcodes that are not in the 3 cities in Ground Truth data
zipcode_s=' or zip_code='.join([ str(s) for s in zip_not_in_gt])
sql_s='select municipal,muni_id,sum(veh_tot)s from grid250m_attributes a,grid_quarters_public g where a.g250m_id=g.g250m_id and quarter="2010_q2" and (zip_code=%s) group by municipal,muni_id'%zipcode_s 
print sql_s
cursor.execute(sql_s)
not_gt_cities=cursor.fetchall()
not_gt_dict={}
for c in not_gt_cities:
  not_gt_dict[c[0]]=c[2]

print 'Zipcodes not in the 3 ground truth cities...'
print not_gt_dict

#Zipcodes that are in no ground truth cities
no_cities_in_gt=zip_not_in_gt-set(not_gt_dict.keys())
print 'Zipcode in no ground truth MA city...'
print no_cities_in_gt

#Cities of the zipcodes that are not sampled 
not_sampled_cities_s= ' or zip_code='.join([ str(s) for s in zip_not_sampled])
sql_s='select municipal,muni_id,sum(veh_tot)s from grid250m_attributes a,grid_quarters_public g  where a.g250m_id=g.g250m_id and quarter="2010_q2" and (zip_code=%s) group by municipal,muni_id'%not_sampled_cities_s
print sql_s
cursor.execute(sql_s)
not_sampled_cities=cursor.fetchall()
not_sampled_cities_dict={}
for c in not_sampled_cities:
  not_sampled_cities_dict[c[0]]=c[2]

print 'Cities/zipcodes that were not sampled'
print not_sampled_cities_dict

#Ground Truth Cities and percent of zipcodes sampled for them
sql_s='select zip_code,municipal,sum(veh_tot)s from grid250m_attributes a,grid_quarters_public g where a.g250m_id=g.g250m_id and quarter="2010_q2" and (muni_id=35 or muni_id=281 or muni_id=348) group by zip_code,municipal'
print sql_s
cursor.execute(sql_s)
gt_zips_cities=cursor.fetchall()
gt_zips_cities_dict={}
gt_zips_cities_numcars_dict={}
for g in gt_zips_cities:
  print 'gt_zips_cities.....'  
  print g[1]  
  if g[1] in gt_zips_cities_dict.keys():
    gt_zips_cities_dict[g[1]].append(g[0])
  else:
    gt_zips_cities_dict[g[1]]=[g[0]]
  if g[0] in gt_zips_cities_numcars_dict.keys():
    gt_zips_cities_dict[(g[0],g[1])].append(g[2])
  else:
    gt_zips_cities_dict[(g[0],g[1])]=[g[2]]

print 'all ground truth cities and zipcodes'
print gt_zips_cities_dict

gt_ims_per_city_dict={}
for gt in gt_zips_cities_dict.keys():
  print gt
  sql_s='select sum(veh_tot)s from grid250m_attributes a,grid_quarters_public g where a.g250m_id=g.g250m_id and quarter="2010_q2" and  municipal="%s"'%gt
  print sql_s
  cursor.execute(sql_s)
  gt_ims_per_city_dict[gt]=cursor.fetchone()[0]

'Number of ground truth cars per city...'
print gt_ims_per_city_dict

gt_zips_percent={}
percent_data_not_sampled=0
for gt in gt_zips_cities_dict.keys():
  zips_in_city=gt_zips_cities_dict[gt]
  zip_not_in_city=set(zips_in_city)-sampled_zipcodes
  percent_not_in_city=100*float(len(zip_not_in_city))/float(len(zips_in_city))
  for z in zip_not_in_city: 
    percent_data_not_sampled += gt_zips_cities_dict[(z,gt)]
    percent_data_not_sampled *= 100/float(gt_ims_per_city_dict[gt])
    gt_zips_percent[gt]=(zip_not_in_city,percent_not_in_city,percent_data_not_sampled)

  print gt_zips_percent




