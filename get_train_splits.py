
if __name__=="__main__":
 lines=open('webgsv_det_train.txt').readlines()
 i=0
 ims=[]
 web_classes={}
 gsv_classes={}
 for l in lines:
   ims.insert(i,l.split(' ')[0])
   i += 1
   k=l.split(' ')[1]
   if 'GSV' in l.split(' ')[2]:
     if k in gsv_classes:
       gsv_classes[k] += 1
     else:
       gsv_classes[k] = 1
   else:
     if k in web_classes:
       web_classes[k] += 1
     else:
       web_classes[k] = 1

 print web_classes.keys()
 print gsv_classes.keys()

 fw=open('web_train_data.txt','w')
 fg=open('gsv_train_data.txt','w')

 for k,v in web_classes.items():
   fw.write('%s,%s\n'%(k,v))

 for k,v in gsv_classes.items():
   fg.write('%s,%s\n'%(k,v))
  
 
