import sys 
import os
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import numpy
import scipy.io
import logging
import Queue
import threading

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
      insert_queries(task[0],task[1],task[2],self.cursor)
      #queue.task_done()

def insert_queries(tuples,chunk,city,cursor):
  print 'executing chunk %d in city %d'%(chunk,city)
  sql_s="insert into detected_cars (x1,y1,x2,y2,desc_val,p1,p2,pscore,group_id,lat,lng,rot) values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
  cursor.executemany(sql_s,tuples)

def getinfo(im_name,cursor):
  sqls='select l.lat,l.lng from geo.samples c,geo.lat_lng_image l where im_fname="%s" and c.lat=l.lat and c.lng=l.lng'%im_name.replace('gsv_unwarp','gsv')
  cursor.execute(sqls)
  lat_lng=cursor.fetchall()
  parts=im_name.split('/')
  rot=int(float(parts[-1].split('_')[3]))
  return repr(lat_lng[0][0]),repr(lat_lng[0][1]),rot

def get_saved_mat_names():
  city_state=open('/tmp/saved_cities_new.csv','rb').readlines()
  savednames= set(['/imagenetdb2/tgebru/gsv_city_done_cnn/%s.mat'%('_'.join([s.split('\t')[0].strip(),s.split('\t')[1].strip()])) for s in city_state])
  logged=open('predictions.log','rb').readlines()
  logged_set=set([l.split(':')[-1].strip() for l in logged])
  print savednames
  print '......................'
  print logged_set
  return savednames.union(logged_set)

if __name__=="__main__":
  logging.basicConfig(filename='predictions.log',level=logging.DEBUG)
  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()
  mat_root='/imagenetdb2/tgebru/gsv_city_done_cnn'
  all_mat_names=set([os.path.join(mat_root,f) for f in os.listdir(mat_root) if f.endswith('mat')])
  saved_mat_names=get_saved_mat_names()
  mat_names=all_mat_names - saved_mat_names
  print all_mat_names,saved_mat_names
  print len(mat_names),len(all_mat_names),len(saved_mat_names)
  queue=Queue.Queue()
   
  num_cities=len(mat_names)
  BATCHSIZE=20
  NUMTHREADS=200

  queue=Queue.Queue()
  for i in range(NUMTHREADS):
    thread = sqlThread(queue)
    #thread.daemon = True
    thread.start()

  i=0
  curChunk=0
  det_list=[]
  det=0
  for mat_name in mat_names:
    try:
      print 'processing city %s %d out of %d'%(mat_name,i,num_cities)
      print 'reading images....'
      mat = scipy.io.loadmat(mat_name)
      num_ims=len(mat['images'][0])
      group_map={}
      filename='/imagenetdb/tgebru/cars/demographics/other_code/class_to_group.txt'
      class_group=open(filename,'rb').readlines() 
      for l in class_group:
        group_map[int(l.split(',')[0])]=int(l.split(',')[1])
    
      #Prediction does not exist
      group_map[-1]=-1
    
      for ind in range(0,num_ims):
        im_name=mat['image_preds']['im_fname'][0][ind][0].encode('ascii')
        bboxes=mat['image_preds']['bboxes'][0][ind]
        preds =mat['image_preds']['preds'][0][ind]
        if len(bboxes>0):
          bb= numpy.concatenate([bboxes,preds],axis=1)
        

        print 'inserting ind %d out of %d in city %d out of %d'%(ind,num_ims,i,num_cities)
        for b in bb:
          x1=int(round(b[0]))
          y1=int(round(b[1]))
          x2=int(round(b[2]))
          y2=int(round(b[3]))
          dpm_random_prior=float(b[4])
          desc_val_prior=float(b[5])
          p1_prior=float(b[6])
          p2_prior=float(b[7])
          pscore=float(b[8])
          pred_class=int(b[28])
          #print x1,y1,x2,y2,dpm_random_prior,desc_val_prior,p1_prior,p2_prior,pscore,pred_class
          group_id=group_map[pred_class]
          lat,lng,rot=getinfo(im_name,cursor)
          
          if len(det_list)==BATCHSIZE:
            queue.put((det_list,curChunk,i))
            curChunk += 1
            det_list=[]
            det_list.append((x1,y1,x2,y2,desc_val_prior,p1_prior,p2_prior,pscore,group_id,lat,lng,rot))

          else:
            det_list.append((x1,y1,x2,y2,desc_val_prior,p1_prior,p2_prior,pscore,group_id,lat,lng,rot))
             
          det += 1
    except:
      logging.debug(mat_name)
  db.close()
