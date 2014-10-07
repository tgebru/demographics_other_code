import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db

class sqlThread(threading.Thread):
  def __init__(self, queue):
    threading.Thread.__init__(self)
    self.queue = queue
    self.db=connect_to_db('all_cars')
    self.cursor=self.db.cursor()

  def run(self):
    thread_name=self.name
    while True:
      task = self.queue.get()
      insert_queries(task[0],task[1],self.cursor)
      queue.task_done()

def insert_queries(tuples,chunk,cursor):
    print 'executing chunk %d'%chunk
    cursor.executemany("""update detected_cars set warped_im_name="%s" where im_name=%s""",tuples)

if __name__=="__main__":
  db=connect_to_db('all_cars')
  cursor=db.cursor()
  sql_s='select distinct im_name from detected_cars'
  print sql_s
  cursor.execute(sql_s)
  ims=cursor.fetchall()

  CHUNKSIZE=10000
  NUMTHREADS=10

  queue=Queue.Queue()
  for i in range(NUMTHREADS):
    thread = sqlThread(queue)
    thread.daemon = True
    thread.start()

  num_ims=len(ims)
  for i in range(0,num_ims,CHUNKSIZE):
    print 'executing chunk %d out of %d'%(i,num_ims)

    im_chunks=ims[i:i+CHUNKSIZE]
    im_names=[im[0] for im in im_chunks]
    warped_names=[im.replace('_unwarp','') for im in im_names]
    tuples=zip(warped_names, im_names)

    print tuples
    queue.put((tuples,i))

  db.close()
