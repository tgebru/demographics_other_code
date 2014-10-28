import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db

if __name__=="__main__":
  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()
  make_query='select distinct(make) from geocars_crawled.control_classes'
  cursor.execute(make_query)
  makes=cursor.fetchall()  

  make_dict={}
  i = 0
  for m in makes:
    make_dict[m[0]]=i
    i += 1

  submodel_query='select distinct(submodel) from geocars_crawled.control_classes'

  cursor.execute(submodel_query)
  submodels=cursor.fetchall()

  submodel_dict={}
  i=0
  for s in submodels:
    submodel_dict[s[0]]=i
    i +=1
  
  country_query='select distinct(country) from geocars.car_metadata'
  cursor.execute(country_query)

  countries=cursor.fetchall()
  country_dict={}
  i=0
  for c in countries:
    country_dict[c[0]]=i
    i +=1

  print make_dict
  print submodel_dict
  print country_dict

  for k,v in make_dict.items():
    query='update geocars.car_metadata m,geocars_crawled.control_classes c set m.make_id=%s where make="%s" and m.group_id=c.group_id'%(v,k)
    print query
    cursor.execute(query)

  for k,v in submodel_dict.items():
    query='update geocars.car_metadata m,geocars_crawled.control_classes c set m.submodel_id=%s where submodel="%s" and m.group_id=c.group_id'%(v,k)
    print query
    cursor.execute(query)

  for k,v in country_dict.items():
    query='update geocars.car_metadata m set country_id=%s where country="%s"'%(v,k)
    print query
    cursor.execute(query)
  
