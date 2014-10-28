function box_data=get_scores(box_data,options)
  for i=1:length(box_data) 
    if(isempty(box_data(i).bboxes))
      continue
    end
    preds=box_data(i).preds;

    %Get top-5 accuracy
    classes_scores=[preds(:,options.num_preds_to_save+1:end),preds(:,1:options.num_preds_to_save)];
    %classes_scores=[preds(:,options.num_preds_to_save+1),preds(:,1)];
    box_data(i).preds=classes_scores;
  end
    
