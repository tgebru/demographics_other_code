import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
db=connect_to_db('geocars')
cursor=db.cursor()
price_quantile=open('price_quantile.txt','rb').readlines()
fine_price_quantile=open('fine_price_quantile.txt','rb').readlines()

for p in price_quantile:
  sql_s='update car_metadata set price_bracket=%s where price=%s'%(p.split(',')[1],p.split(',')[0])
  cursor.execute(sql_s)
  print sql_s

for p in fine_price_quantile:
  sql_s='update car_metadata set fine_price_bracket=%s where price=%s'%(p.split(',')[1],p.split(',')[0])
  print sql_s
  cursor.execute(sql_s)

db.close()
