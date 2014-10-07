import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db

countries=open('/tmp/makes.csv','rb').readlines()
db=connect_to_db('geocars')
cursor=db.cursor()
for c in countries:
  parts=c.split(',')
  sql='select group_id from synsets where make="%s" and group_id is not null'%parts[0].strip()
  print sql
  cursor.execute(sql)
  group_ids=cursor.fetchall()
  for g in group_ids:
    print parts[0],g
    sql='update car_metadata set country="%s",is_foreign=%s where group_id=%s'%(parts[1].strip(),parts[2].strip(),g[0])
    print sql
    cursor.execute(sql)
db.close()
