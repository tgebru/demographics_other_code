import glob, re
import pandas as pd
import numpy as np
from numpy import nan
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

#need for Download URL module from Jia
#browser_id=15
browser_id=12

class ThreadURL(threading.Thread):
  def __init__(self, queue,out_queue):
    threading.Thread.__init__(self)
    self.queue = queue
    self.out_queue = out_queue
    db=connect_to_db('demo')
    cursor=db.cursor()
    self.cursor = cursor
    #self.b=network.QueryBrowser(browser_id)
    self.b=network.ThumbBrowser(browser_id)

  def run(self):
    while True:
      query = self.queue.get()
      print "running: %s" %(self.name)
      fips=get_fips(query,self.b,self.cursor)
      if fips:
        self.out_queue.put(fips)
      else:
        self.queue.put(query)

      if queue.empty():
         queue.task_done()
         out_queue.task_done()
         print "done: %s" %self.name
         break 
      else:
         queue.task_done()
         out_queue.task_done()

def get_lat_longs(cursor):
  try:
    with open('lat_longs.p','wb') as f:
      print 'getting latlongs from pickle.... '
      latlongs=pickle.load(f)
  except IOError:
    print 'getting latlongs from table.... '
    sql_s=' select lat,lng from geo.samples where sampled=1 and good_gps=1 order by lat,lng'
    cursor.execute(sql_s)
    latlongs= cursor.fetchall()
    with open('lat_longs.p','wb') as f:
      pickle.dump(latlongs,f)

  return latlongs

def store_fips(fp_code,cursor):
  cursor.execute('insert ignore into demo.latlong_fpis (lat,lng,fpis) values(%s,%s,%s)',(fp_code[0],fp_code[1],fp_code[2]))  

def get_fips(tup,br,cursor):
  url = "http://data.fcc.gov/api/block/2010/find?latitude=40.0&longitude=-85"
  latitude = "latitude=" + str(tup[0])
  longitude = "&longitude=" + str(tup[1])
  url = url_base + latitude + longitude
  data=follow_link(br,url)
  #urlobj = urllib.urlopen(url)
  #data = urlobj.read()
  if data is None:
     return 
  soup = BeautifulStoneSoup(data)
  blck = dict(soup.find("block").attrs)
  if 'fips' in blck:
    fips = str(blck['fips'])
  else:
    fips='null'
  #print '%s %s %s'%(latitude,longitude,fips)
  store_fips((tup[0],tup[1],fips),cursor)
  return (tup[0],tup[1],fips)

def follow_link(br,link):
   print '......link=%s..................'%link
   tried=0
   connected=False
   html=''
   num_to_try=10
   html=br.DownloadURL(link)
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
  db=connect_to_db('backup_geocars')
  cursor=db.cursor()
  lat_longs=get_lat_longs(cursor)
  url_base = "http://data.fcc.gov/api/block/2010/find?"
  queue = Queue.Queue()
  out_queue = Queue.Queue()
  num_threads=1000

  #Pull fips codes for all lat/longs
  num_tuples=len(lat_longs)
  count = 0
  for tup in lat_longs:
    count += 1
    print 'adding %s out of %s...'%(count,num_tuples)
    queue.put(tup)

  start= time.time()
  for i in range(num_threads):
    thread = ThreadURL(queue,out_queue)
    thread.start()
  queue.join()
  out_queue.join()

  stop = time.time()

  while True:
    print(out_queue.get())
    if out_queue.empty():
      break
  print 'took %d seconds' %(stop-start)
  db.close
  db1.close
