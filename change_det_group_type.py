import sys 
import os
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db


if __name__=="__main__":
  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()

  cursor.execute('''show tables from all_cars''')  
  tables=cursor.fetchall()
  for t in tables:
    sql_s='alter table %s  modify group_id int(4)'%(t[0])
    print sql_s
    cursor.execute(sql_s)
