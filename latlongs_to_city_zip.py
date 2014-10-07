import logging
import glob, re
import urllib
import json
from BeautifulSoup import BeautifulStoneSoup
import sys 
sys.path.append('/imagenetdb/tgebru/') 
from mysql_utils import connect_to_db
import Queue
import threading
sys.path.append('/imagenetdb/jiadeng/crawler_demo')
import network
import time
import pickle
import json

#need for Download URL module from Jia
#browser_id=15
browser_id=12
logging.basicConfig(filename='log.log',level=logging.DEBUG)

class ThreadURL(threading.Thread):
  def __init__(self, queue):
    threading.Thread.__init__(self)
    self.queue = queue
    db=connect_to_db('demo')
    cursor=db.cursor()
    self.cursor = cursor
    #self.b=network.QueryBrowser(browser_id)
    self.b=network.ThumbBrowser(browser_id)

  def run(self):
    while True:
      query = self.queue.get()
      print "running: %s" %(self.name)
      city_zip=get_city_zip(query,self.b,self.cursor)

      if city_zip==1:
        logging.debug(query)
        logging.debug('\n')
       
      if queue.empty():
         queue.task_done()
         print "done: %s" %self.name
         break 
      else:
         queue.task_done()

def get_lat_longs(cursor):
  try:
    with open('lat_longs.p','wb') as f:
      print 'getting latlongs from pickle.... '
      latlongs=pickle.load(f)
  except IOError:
    print 'getting latlongs from table.... '
    sql_s=' select lat,lng from demo.latlong_fpis where city is null'
    cursor.execute(sql_s)
    latlongs= cursor.fetchall()
    with open('lat_longs.p','wb') as f:
      pickle.dump(latlongs,f)

  return latlongs

def store_city_zip(lat,lng,city,zipcode,cursor):
  cursor.execute('update demo.latlong_fpis set city=%s,zipcode=%s where lat=%s and lng=%s',(city,zipcode,lat,lng))

def get_city_zip(tup,br,cursor):
  latlong = '%s,%s'%(str(tup[0]),str(tup[1]))
  url = url_base + latlong + "&sensor=true"
  data=follow_link(br,url)
  if data is None:
     return 1
  soup = BeautifulStoneSoup(data)
  newDict=json.loads(str(soup))
  try:
    results= newDict['results'][0]
    city_assigned=False
    zip_assigned=False
    for r in results['address_components']:
      if 'locality' in r['types']:
        city= r['long_name']
        city_assigned=True
      if 'postal_code' in r['types']:
        zipcode=r['long_name']
        zip_assigned=True
      if city_assigned and zip_assigned: break
    
    store_city_zip(tup[0],tup[1],city,zipcode,cursor)
  except:
    print 'Cannot get %s'%latlong
    print data
    return 1 
  return 0

def follow_link(br,link):
   print '......link=%s..................'%link
   tried=0
   connected=False
   html=''
   num_to_try=10
   while not connected:
      try:
        html=br.DownloadURL(link)
        connected = True # if line above fails, this is never executed
      except Exception as e: #catch all exceptions
        print 'Error in follow_link: %s trying again' %e
        tried += 1        
        if tried > num_to_try:
          print 'cannot download from link: %s' %link
          return 
   return html 

if __name__=="__main__":
  #Load latitude and longitudes
  db=connect_to_db('')
  cursor=db.cursor()
  lat_longs=get_lat_longs(cursor)
  url_base = "http://maps.googleapis.com/maps/api/geocode/json?latlng="
  queue = Queue.Queue()
  num_threads=100

  #Pull zip codes and city names for all lat/longs
  num_tuples=len(lat_longs)
  count = 0
  for tup in lat_longs:
    count += 1
    print 'adding %s out of %s...'%(count,num_tuples)
    queue.put(tup)

  start= time.time()
  for i in range(num_threads):
    thread = ThreadURL(queue)
    thread.start()
  queue.join()

  stop = time.time()
  print 'took %d seconds' %(stop-start)
  db.close
