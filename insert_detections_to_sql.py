import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import Queue
import threading
import resource
import time
import logging

class cityThread(threading.Thread):
  def __init__(self, queue,logging):
    threading.Thread.__init__(self)
    self.queue = queue
    self.db=connect_to_db('all_cars')
    self.cursor=self.db.cursor()
    self.logging=logging
  def run(self):
    thread_name=self.name
    while True:
      query = self.queue.get()
      insert_queries(query,self.cursor,logging)
      if queue.empty():
        print "done: %s" %thread_name
        self.db.close()
        queue.task_done()
        break 
      else:
        queue.task_done()

def insert_queries(q,cursor,logging):
  logging.debug(q)
  cursor.execute(q)

def limit_resource():
   megs=1000000
   rsrc = resource.RLIMIT_AS
   soft, hard = resource.getrlimit(rsrc)
   print 'Soft limit starts as  :', soft
   resource.setrlimit(rsrc, (8*megs*1024, 8*megs*1024)) #limit to 8  Gigabytes
   soft, hard = resource.getrlimit(rsrc)
   print 'Soft limit changed to :', soft

if __name__=='__main__':
  NUMCITIES=200
  NUMTHREADS=10
  limit_resource()
  start_time=time.time()
  logging.basicConfig(filename='log.log',level=logging.DEBUG)

  queue=Queue.Queue()
  for i in range(NUMTHREADS):
    thread = cityThread(queue,logging)
    thread.start()

  num_detections=0
  #Read sql lines printed from matlab
  for i in range(1,10):#NUMCITIES+1):
    print 'reading ciy # %d'%i
    queries=open('all_detected_cars_data_%d.txt'%i).readlines()
    for q in queries:
      queue.put(q.strip())
    l=len(queries)
    num_detections += l
    logging.debug('city %d has %d detections'%(i,l))
    logging.debug('%d total detections so far'%num_detections)
  queue.join()
  t= start_time-time.time()
  print t
  logging.debug('putting to sql took %d seconds'%t)

  #Put latitude longitude in table
  print 'putting in lattitudes and longitudes'
  db=connect_to_db('all_cars')
  self.cursor=db.cursor()
  sql_s='update detected_cars m,geo.lat_lng_image g set m.lat=g.lat,m.lng=g.lng where m.im_name=g.im_fname'  
  print sql_s
  cursor.execute(sql_s)

  sql_s='select count(*) from detected_cars'
  cursor.execute(sql_s) 
  num_in_sql=cursor.fetchone()
  loggging.debug('Number of detections: %d',num_detections) 
  loggging.debug('Number in sql: %d',num_in_sql)
  db.close()


