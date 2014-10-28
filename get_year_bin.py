import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db

def get_year_bin(year):
  year_bin=-1
  if int(year)>=1990 and int(year)<=1994:
    year_bin=0
  elif int(year)>=1995 and int(year)<=1999:
    year_bin=1
  elif int(year)>=2000 and int(year)<=2004:
    year_bin=2
  elif int(year)>=2005 and int(year)<=2009:
    year_bin=3
  elif int(year)>=2010:
    year_bin=4

  return year_bin

if __name__=="__main__":
  db_name='geocars'
  db=connect_to_db(db_name)
  cursor=db.cursor()
  root_dir='/imagenetdb3/mysql_tmp_dir/car_census'

  sqls='select group_id,years from geocars_crawled.control_classes'
  cursor.execute(sqls)
  res=cursor.fetchall()
  group_year_list=[]
  f=open('group_year.txt','w')
  i=0
  for r in res:
    i += 1
    print i    
    year=r[1].split('_')[0]
    print r
    try:
      year_bin=get_year_bin(year)
    except: 
      year_q='select year from synsets where group_id=%s'%r[0]
      cursor.execute(year_q)
      years=cursor.fetchall()
      max_year=0
      min_year=3000
      for y in years:
        if int(y[0])<min_year: min_year=int(y[0])
        if int(y[0])>max_year: max_year=int(y[0])
      print min_year
      year_bin=get_year_bin(min_year)

    assert(year_bin>=0) 
    print r[0],year,year_bin
    f.write('%s,%d\n'%(r[0],year_bin))
      
          

