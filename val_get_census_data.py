import sys 
sys.path.append('/imagenetdb/tgebru/') 
sys.path.append('/imagenetdb/jiadeng/crawler_demo')
from latlongs_to_FIPS import follow_link
from mysql_utils import connect_to_db
import network
import Queue
import threading
import time

LEVEL='zipcode'
DATA_TYPE='acs'

if DATA_TYPE=='census':
  URL_BASE='http://api.census.gov/data/2010/sf1?key='
else:
  if LEVEL=='zipcode':
    URL_BASE='http://api.census.gov/data/2012/acs5?key='
  else:
    URL_BASE='http://api.census.gov/data/2010/acs5?key='

API_KEY='c3f2b964f8b400372d5b511a32860df212775373'
BASE='%s%s&get='%(URL_BASE,API_KEY)
BROWSER_ID=12

class ThreadURL(threading.Thread):
  def __init__(self, queue):
    threading.Thread.__init__(self)
    self.queue = queue
    db=connect_to_db('demo')
    cursor=db.cursor()
    self.cursor = cursor
    #self.b=network.QueryBrowser(BROWSER_ID)
    self.b=network.ThumbBrowser(BROWSER_ID)

  def run(self):
    while True:
      fips = self.queue.get()
      print "running: %s fips=%s" %(self.name,fips)
      status=get_info(fips,self.b,self.cursor)
      if status:
        self.queue.put(fips)

      if queue.empty():
         queue.task_done()
         print "done: %s" %self.name
         break 
      else:
         queue.task_done()

def make_cols(cursor,input):
  input=input.split(',')
  print input
  for d in input:
    d=d.replace(' ','_')
    sqls='show columns from demo.%s_%s like "%s"'%(LEVEL,DATA_TYPE,d)
    cursor.execute(sqls)
    ans=cursor.fetchall()
    if not ans:
      sqls='alter table demo.%s_%s add column %s integer(6)'%(LEVEL,DATA_TYPE,d)
      cursor.execute(sqls)

def store_in_db(fips,data,vars_list,cursor):
    try:
      print 'instore'
      data=data.replace("[[","")
      data=data.replace("]]","")
      keys=data.split(']')[0]
      values=data.split(']')[1]
      values=values.replace('[','')
      keys=keys.replace('"','').replace(' ','_').strip().replace('\n','')
      values=values.replace('"','').strip().replace('\n','')
      make_cols(cursor,keys)
      sql_s='insert ignore into demo.%s_%s (fips,%s) values(%s%s)'%(LEVEL,DATA_TYPE,keys,fips.strip(),values)
      print sql_s
      cursor.execute(sql_s)
    except:
      sys.stderr.write('%s\n'%fips) 
     
def get_vars_list():
  vars=open('%s_variables.txt'%DATA_TYPE).readlines()
  var_keys=[]
  for v in vars:
    var_keys.append(v.split(',')[0])
  return var_keys

def get_zipcode(state,county,tract,cursor):
  sqls='select zcta5 from demo.zcta_tract where state=%s and county=%s and tract=%s'%(state,county,tract)
  cursor.execute(sqls)
  zcta5=cursor.fetchone()
  return zcta5[0]

def get_info(fips,br,cursor):
  if len(str(fips))==14:
    fips='0%s'%fips
  fips=str(fips)
  state = fips[0:2]
  county= fips[2:5]
  tract = fips[5:11]
  block = fips[11:15]
  vars_list=get_vars_list()
  vars=",".join(vars_list)

  if LEVEL=='block':
    query='%s%s&for=block:%s&in=state:%s+county:%s+tract:%s'%(BASE,vars,block,state,county,tract)
  elif LEVEL=='tract':
    query='%s%s&for=tract:%s&in=state:%s+county:%s'%(BASE,vars,tract,state,county)
  elif LEVEL=='zipcode':
    zipcode=get_zipcode(state,county,tract,cursor)
    #query='%s%s&for=zip+code+tabulation+area:%s&in=state:%s'%(BASE,vars,zipcode,state)
    query='%s%s&for=zip+code+tabulation+area:%s'%(BASE,vars,zipcode)

  print query
  data=follow_link(br,query)
  if data is None:
    return 1
  print data
  store_in_db(fips,data,vars_list,cursor)
  return 0

def get_fips(cursor,table_name):
  print 'Getting FIPS'
  sqls ='select im_name from all_cars.%s'%table_name
  cursor.execute(sqls)
  ims=cursor.fetchall()
  fips=[]
  i=0
  for im in ims:
    i += 1
    im_parts=im[0].split('_')
    lat=im_parts[1]
    lng=im_parts[2]
    sqls='select fpis from demo.latlong_fpis where lat=%s and lng=%s'%(lat,lng)
    print im[0],lat,lng
    cursor.execute(sqls)
    res=cursor.fetchone()
    fips.append(res[0])
  return fips

def get_unstored_fips(cursor):
  fips=[]
  lat_lngs=open('stderr.log').readlines()
  i=0
  for l in lat_lngs:
    i += 1
    sqls='select fpis from demo.latlong_fpis where lat=%s and lng=%s'%(l.split(',')[0],l.split(',')[1].split(' ')[0].strip())
    cursor.execute(sqls)
    res=cursor.fetchone()
    fips.append(res[0])
    print res[0]
  return fips
    
if __name__=="__main__":
  db=connect_to_db('all_cars')
  cursor=db.cursor()
  table_name='train_val_gt_detected_cars';
  #fips=get_fips(cursor,table_name)
  fips=get_unstored_fips(cursor)
  queue = Queue.Queue()
  NUM_THREADS=100
  i=0
  for f in fips:
    i += 1
    if f==0:
      print f
    else:
      queue.put(f)

  start=time.time()
  for i in range(NUM_THREADS):
    thread = ThreadURL(queue)
    thread.start()
  queue.join()
  
  stop = time.time()-start
  print 'Took %f secs' %stop

