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
URL_BASE='http://api.census.gov/data/2010/sf1?key='
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

def store_in_db(fips,data,vars_list,cursor):
  dict=eval(data)
  keys=",".join(dict[0])
  for d in dict[1:]:
    d_str=",".join(d)
    sql_s='insert into census (fips,%s) values(%s,%s)'%(keys,fips,d_str)
  print sql_s
  cursor.execute(sql_s)
     
def get_info(fips,br,cursor):
  if len(fips)==14:
    fips='0%s'%fips
  print fips
  state = fips[0:2]
  county= fips[2:5]
  tract = fips[5:11]
  block = fips[11:15]
  #vars='PCT012A015,PCT012A119'
  vars_list=['P0030001']
  vars=",".join(vars_list)

  query='%s%s&for=block:%s&in=state:%s+county:%s+tract:%s'%(BASE,vars,block,state,county,tract)
  print query
  data=follow_link(br,query)
  if data is None:
    return 1
  store_in_db(fips,data,vars_list,cursor)
  return 0

def get_fips(cursor,table,col):
  print 'Getting FIPS'
  sql_s='select distinct(%s) from demo.%s where %s<>0'%(col,table,col)
  cursor.execute(sql_s)
  fips=cursor.fetchall()
  return fips

if __name__=="__main__":
  db=connect_to_db('backup_geocars')
  cursor=db.cursor()
  fips=get_fips(cursor,'latlong_fpis','fpis')
  stored_fips=get_fips(cursor,'census','fips')
  unstored_fips=set(fips)-set(stored_fips)
  print len(stored_fips),len(unstored_fips),len(fips)
  queue = Queue.Queue()
  NUM_THREADS=100
  i=0
  for f in unstored_fips:
    i += 1
    f=str(f[0])
    queue.put(f)

  start=time.time()
  for i in range(NUM_THREADS):
    thread = ThreadURL(queue)
    thread.start()
  queue.join()
  
  stop = time.time()-start
  print 'Took %f secs' %stop

