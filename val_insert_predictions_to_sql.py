import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import scipy.io
import numpy

if __name__=="__main__":
  mat_name='/afs/cs.stanford.edu/u/tgebru/cars/code/cnn/gsv_classify/val_data.mat'

  db_name='all_cars' 
  db = connect_to_db(db_name)
  cursor = db.cursor()
  mat = scipy.io.loadmat(mat_name)
  num_ims=len(mat['images'][0])
  group_map={}
  filename='/imagenetdb/tgebru/cars/demographics/other_code/class_to_group.txt'

  #map clases to group_ids
  class_group=open(filename,'rb').readlines() 
  for l in class_group:
    group_map[int(l.split(',')[0])]=int(l.split(',')[1])
  
  #Prediction does not exist
  group_map[-1]=-1

  for ind in range(0,num_ims):
    imageid=mat['images']['imageid'][0][ind]
    im_name=mat['image_preds']['im_fname'][0][ind][0].encode('ascii')
    bboxes=mat['image_preds']['bboxes'][0][ind]
    preds =mat['image_preds']['preds'][0][ind]
    if len(bboxes>0):
      bb= numpy.concatenate([bboxes,preds],axis=1)

    print 'inserting ind %d out of %d'%(ind,num_ims)
    for b in bb:
      x1=int(round(b[0]))
      y1=int(round(b[1]))
      x2=int(round(b[2]))
      y2=int(round(b[3]))
      dpm_random=float(b[4])
      desc_val=float(b[5])
      p1=float(b[6])
      p2=float(b[7])
      pscore=float(b[8])
      pred_class=int(b[28])
      group_id=group_map[pred_class]
      
      sql_s='insert ignore into val_detected_cars (im_name,x1,y1,x2,y2,dpm_random,desc_val, \
        p1,p2,pscore,class,group_id) values("%s",%d,%d,%d,%d,%f,%f,%f,%f,%f,%d,%d)' \
         %(im_name,x1,y1,x2,y2,dpm_random,desc_val,p1,p2,pscore,pred_class,group_id)
      print sql_s
      cursor.execute(sql_s)

    gt_bboxes=mat['images']['bboxes'][0][ind]
    group_ids=mat['images']['group_ids'][0][ind]
    classes=mat['images']['classes'][0][ind]
    big_enough=mat['images']['big_enough'][0][ind]

    if len(gt_bboxes)>0:
      for b,g_id,cls,be in zip(gt_bboxes,group_ids[0],classes[0],big_enough[0]):
        x1=int(round(b[0]))
        y1=int(round(b[1]))
        x2=int(round(b[2]))
        y2=int(round(b[3]))
        
        print x1,y1,x2,y2,g_id,cls,be
        sql_s='insert ignore into gt_val_detected_cars (imageid,im_name,x1,y1,x2,y2,class,group_id,big_enough) values(%d,"%s",%d,%d,%d,%d,%d,%d,%d)'%(imageid,im_name,x1,y1,x2,y2,cls,g_id,be)  
        print sql_s
        cursor.execute(sql_s)
  db.close()
