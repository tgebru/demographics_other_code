function [ap, prec, rec] =dpm_eval(path_filename,id_filename,gt_bbox_filename,dpm_bbox_filename,num_ims,draw_bboxes,draw_prec,recalculate_dpm,model_name,threshold,default)
  minoverlap=0.5
  ims=get_ims(path_filename,num_ims);
  [gt_bboxes,num_gt_boxes]=get_gt_bboxes(gt_bbox_filename,num_ims);
  [dpm_bboxes,num_dpm_boxes]=get_dpm_bboxes(ims,dpm_bbox_filename,num_ims,draw_bboxes,recalculate_dpm,model_name,threshold,default);
  [all_dpm_bboxes,im_no,conf]=sort_dpm_bboxes(dpm_bboxes,num_ims,num_dpm_boxes);
  tp=zeros(num_dpm_boxes,1);
  fp=zeros(num_dpm_boxes,1);
  detected_dpm_bboxes=cell(num_ims,1);
  detected=cell(num_ims,1);

  for ndpm=1:num_dpm_boxes
    fprintf('calulating detection for dpm box #%d out of #%d\n',ndpm,num_dpm_boxes);
      num_gt_im_boxes=size(gt_bboxes{im_no(ndpm)},1);
      if isempty(detected{im_no(ndpm)})
        detected{im_no(ndpm)}=zeros(num_gt_im_boxes,1);
      end
      bb=all_dpm_bboxes(ndpm,:);
      ovmax=-inf;
      for g=1:num_gt_im_boxes
        bbgt=gt_bboxes{im_no(ndpm)}(g,:); 
        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
        iw=bi(3)-bi(1)+1;
        ih=bi(4)-bi(2)+1;
        if iw>0 & ih>0                
          % compute overlap as area of intersection / area of union
          ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
            (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
            iw*ih;
          ov=iw*ih/ua;
          if ov>ovmax
            ovmax=ov;
            jmax=g;
          end
        end
      end
      % assign detection as true positive/don't care/false positive
      im_detected=detected{im_no(ndpm)};
      if ovmax>=minoverlap
         if ~im_detected(jmax)
           tp(ndpm)=1; %true positive
           detected{im_no(ndpm)}(jmax)=1;
           detected_dpm_bboxes{im_no(ndpm)}=[detected_dpm_bboxes{im_no(ndpm)};bb]; 
         else
           fp(ndpm)=1;%false positive (multiple detections)
         end
      else
         fp(ndpm)=1; %false positive 
      end
  end

  save_dpm_boxes(detected_dpm_bboxes,['dpm_bboxes/detected_dpm_' dpm_bbox_filename])
  % compute precision/recall
  npos=num_gt_boxes;
  fp=cumsum(fp);
  tp=cumsum(tp);

  rec=tp/npos;
  prec=tp./(fp+tp);
  ap=VOCap(rec,prec);

  if draw_prec
      % plot precision/recall
      plot(rec,prec,'-');
      grid;
      xlabel 'recall'
      ylabel 'precision'
      %title(sprintf('class: %s, subset: %s, AP = %.3f',cls,VOCopts.testset,ap));
  end
