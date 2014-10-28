function [lat,lng]= get_lat_lng(im_name)
  splitStr = regexp(im_name,'_','split');
  lat=splitStr(2);
  lng=splitStr(3);

