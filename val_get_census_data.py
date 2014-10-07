import sys 
sys.path.append('/imagenetdb/tgebru/') 
sys.path.append('/imagenetdb/jiadeng/crawler_demo')
from latlongs_to_FIPS import follow_link
from mysql_utils import connect_to_db
import network
import Queue
import threading
import time

API_KEY='c3f2b964f8b400372d5b511a32860df212775373'
#URL_BASE='http://api.census.gov/data/2010/sf1?key='
URL_BASE='http://api.census.gov/data/2010/acs5?key='
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
  for d in input:
    sqls='show columns from demo.tract_acs like "%s"'%d
    cursor.execute(sqls)
    ans=cursor.fetchall()
    if not ans:
      sqls='alter table demo.tract_acs add column %s integer(6)'%d
      cursor.execute(sqls)

def store_in_db(fips,data,vars_list,cursor):
  try:
    dict=eval(data)
    keys=",".join(dict[0])
    make_cols(cursor,dict[0])
    for d in dict[1:]:
      d_str=",".join(d)
      sql_s='insert ignore into demo.tract_acs (fips,%s) values(%s,%s)'%(keys,fips.strip(),d_str)
    print sql_s
    cursor.execute(sql_s)
  except:
    sys.stderr.write('%s\n'%fips) 
     
def get_vars_list():
  vars=open('acs_variables.txt').readlines()
  #vars=open('acs_variables.txt').readlines()
  var_keys=[]
  for v in vars:
    var_keys.append(v.split(',')[0])
  return var_keys

def get_info(fips,br,cursor):
  if len(str(fips))==14:
    fips='0%s'%fips
  fips=str(fips)
  state = fips[0:2]
  county= fips[2:5]
  tract = fips[5:11]
  block = fips[11:15]
  #vars='PCT012A015,PCT012A119'
  #vars_list=['P0030001']
  vars_list=get_vars_list()
  vars=",".join(vars_list)

  #query='%s%s&for=block:%s&in=state:%s+county:%s+tract:%s'%(BASE,vars,block,state,county,tract)
  query='%s%s&for=tract:%s&in=state:%s+county:%s'%(BASE,vars,tract,state,county)
  print query
  data=follow_link(br,query)
  if data is None:
    return 1
  store_in_db(fips,data,vars_list,cursor)
  return 0

def get_fips(cursor,table_name):
  print 'Getting FIPS'
  sqls ='select im_name from all_cars.gt_val_detected_cars'
  cursor.execute(sqls)
  ims=cursor.fetchall()
  fips=[]
  for im in ims:
    im_parts=im[0].split('_')
    lat=im_parts[1]
    lng=im_parts[2]
    sqls='select fpis from demo.latlong_fpis where lat=%s and lng=%s'%(lat,lng)
    print im[0],lat,lng
    cursor.execute(sqls)
    res=cursor.fetchone()
    fips.append(res[0])
  return fips

if __name__=="__main__":
  db=connect_to_db('all_cars')
  cursor=db.cursor()
  val_table_name='gt_val_detected_cars';
  fips=get_fips(cursor,val_table_name)
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

