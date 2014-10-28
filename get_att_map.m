function [att_map,num_out_bins]=get_att_map(att_num,num_bins);
  if (att_num==2)
    att_map=class_to_priceid_map(num_bins);
  elseif (att_num==3)
    att_map=class_to_makeid_map();
  elseif (att_num==4)
    att_map=class_to_submodelid_map();
  elseif (att_num==5)
    att_map=class_to_countryid_map();
  elseif (att_num==6)
    att_map=class_to_foreignid_map();
  elseif (att_num==7)
    att_map=class_to_yearid_map();
  end
  num_out_bins=numel(unique(cell2mat(att_map.values())));
