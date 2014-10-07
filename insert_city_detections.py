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
      insert_queries(task[0],task[1],task[2],task[3],self.cursor)
      #queue.task_done()

def insert_queries(tuples,chunk,city,cityid,cursor):
  print 'executing chunk %d in city %d'%(chunk,city)
  '''
  sql_s="insert into city_%d_detected_cars (lat,lng,rot,x1,y1,x2,y2,desc_val,p1,p2,pscore,group_id) values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"
  cursor.executemany(sql_s,tuples)
  '''

  cursor.executemany('insert ignore into city_%d_detected_cars (lat,lng,rot,x1,y1,x2,y2,desc_val,p1,p2,pscore,group_id) values(%%s,%%s,%%s,%%s,%%s,%%s,%%s,%%s,%%s,%%s,%%s,%%s)'%cityid,tuples)

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

def get_cityid(mat_name,cursor):
  sql_s='select cityid from geo.cities where cityname="%s" and state="%s"'%(mat_name[:-4].split('_')[0],mat_name[:-4].split('_')[1])
  print sql_s
  cursor.execute(sql_s)
  cityid=cursor.fetchone()
  return cityid[0]

def create_table(cityid,cursor):
  sql_s='create table if not exists city_%d_detected_cars \
  (id int not null auto_increment primary key, lat decimal(9,6), lng decimal(9,6), rot int(3),group_id int(5),x1 int(3),y1 int(3),x2 int(3),y2 int(3),desc_val double,p1 double,p2 double,pscore double)'%cityid
  print sql_s
  cursor.execute(sql_s)

  sql_s='SELECT COUNT(1) IndexIsThere FROM INFORMATION_SCHEMA.STATISTICS\
   WHERE table_schema=DATABASE() AND table_name="city_%d_detected_cars" AND \
  index_name="lat_lng"'%cityid
  print sql_s
  cursor.execute(sql_s)
  index_there=cursor.fetchone()
  print index_there
  if not index_there or index_there[0]==0:
    sql_s='create index lat_lng on city_%d_detected_cars(lat,lng)'%cityid
    cursor.execute(sql_s)
    print sql_s
    sql_s='create unique index lat_lng_ent on city_%d_detected_cars(lat,lng,x1,y1,x2,y2)'%cityid
  print sql_s
  cursor.execute(sql_s)

if __name__=="__main__":
  #cityind=sys.argv[1]
  fid=open('citydets.txt','w')
  fid.write('cityid,num_dets\n')
  logging.basicConfig(filename='city_predictions.log',level=logging.DEBUG)
  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()
  mat_root='/imagenetdb2/tgebru/gsv_city_done_cnn'
  all_mat_names=set([os.path.join(mat_root,f) for f in os.listdir(mat_root) if f.endswith('mat')])
  #saved_mat_names=get_saved_mat_names()
  #mat_names=all_mat_names - saved_mat_names
  #print all_mat_names,saved_mat_names
  #print len(mat_names),len(all_mat_names),len(saved_mat_names)
  mat_names=all_mat_names
  queue=Queue.Queue()
   
  num_cities=len(mat_names)
  BATCHSIZE=100
  NUMTHREADS=20

  queue=Queue.Queue()
  for i in range(NUMTHREADS):
    thread = sqlThread(queue)
    #thread.daemon = True
    thread.start()

  i=0
  curChunk=0
  det_list=[]
  det=0

  group_map={}
  filename='/imagenetdb/tgebru/cars/demographics/other_code/class_to_group.txt'
  class_group=open(filename,'rb').readlines() 
  for l in class_group:
    group_map[int(l.split(',')[0])]=int(l.split(',')[1])

  CITYSIZE=50
  #for i in xrange(cityind,cityind+CITYSIZE+1):
  #mat_name=mat_names[i]
  for mat_name in mat_names:
    i += 1
    if i<133:continue
    try:
      print 'processing city %s %d out of %d'%(mat_name,i,num_cities)
      print 'reading images....'
      city_name=os.path.split(mat_name)[-1]
      print 'city %s...'%city_name
      cityid=get_cityid(city_name,cursor)
      create_table(cityid,cursor)
      mat = scipy.io.loadmat(mat_name)
      num_ims=len(mat['images'][0])
    
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
            queue.put((det_list,curChunk,i,cityid))
            curChunk += 1
            det_list=[]
            det_list.append((lat,lng,rot,x1,y1,x2,y2,desc_val_prior,p1_prior,p2_prior,pscore,group_id))

          else:
            det_list.append((lat,lng,rot,x1,y1,x2,y2,desc_val_prior,p1_prior,p2_prior,pscore,group_id))
             
          det += 1
      if not det_list:
        queue.put((det_list,curChunk,i,cityid))
      fid.write('%d,%d\n'%(int(cityid),det))
    except:
      logging.debug(mat_name)
  fid.close()
  db.close()
