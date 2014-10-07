import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db

db=connect_to_db('demo')
cursor=db.cursor()

sql_s='show tables from demo like "%SF1%"'
cursor.execute(sql_s)
tables=cursor.fetchall()
for t in tables:
  sql_s='drop table %s'%t[0]
  print sql_s
  cursor.execute(sql_s)

