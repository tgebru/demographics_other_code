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
      queue.task_done()
      '''
      if queue.empty():
        print "done: %s" %thread_name
        self.db.close()
        queue.task_done()
        break 
      else:
        queue.task_done()
      '''

def insert_queries(q,cursor,logging):
  #logging.debug(q)
  print q
  cursor.execute(q)
  #cursor.executemany(q[0],q[1]))

def limit_resource():
   megs=1000000
   rsrc = resource.RLIMIT_AS
   soft, hard = resource.getrlimit(rsrc)
   print 'Soft limit starts as  :', soft
   resource.setrlimit(rsrc, (8*megs*1024, 8*megs*1024)) #limit to 8  Gigabytes
   soft, hard = resource.getrlimit(rsrc)
   print 'Soft limit changed to :', soft

def chunker(seq, size):
  return (seq[pos:pos + size] for pos in xrange(0, len(seq), size))

if __name__=='__main__':
  NUMCITIES=200
  NUMTHREADS=10
  MAXSIZE=10000000
  CHUNKSIZE=10000
  SLEEP=10
  limit_resource()
  start_time=time.time()
  logging.basicConfig(filename='log.log',level=logging.DEBUG)

  queue=Queue.Queue(maxsize=MAXSIZE)
  for i in range(NUMTHREADS):
    thread = cityThread(queue,logging)
    thread.daemon = True
    thread.start()

  num_detections=0
  #Read sql lines printed from matlab
  queries=open('train_gt_cars_data.txt').readlines()
  l=len(queries)
  num_detections += l

  #for group in chunker(queries,CHUNKSIZE):
  for q in queries:
    try:
      queue.put(q.strip(),block=False)
      #queue.put((STATEMENT,group),block=False)
    except Queue.Full:
      print 'Queue full sleeping for %d seconds'%SLEEP
      logging.debug('Queue full...')
      time.sleep(SLEEP)
      print 'waking up...'
  queue.join()
  t= time.time-start_time
  print t
  logging.debug('putting to sql took %d seconds'%t)


