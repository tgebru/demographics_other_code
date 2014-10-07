import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
db=connect_to_db('geocars')
cursor=db.cursor()

#load validation mat file

#Get census variables for each bbox

#Get car attributes for each bbox


