function [new_classes,new_probs,acc,ac5]=recalculate_probs(cur_classes,...
  cur_probs,gt_classes,input_map,delta_bins);

value_vector=map_to_vector(input_map);

num_inputs=size(cur_probs,1);
gt_value=zeros(size(gt_classes));
for i=1:num_inputs
  cur_atts(i,:)=value_vector(cur_classes(i,:)+1);
  gt_value(i)=value_vector(gt_classes(i)+1);
end
 
num_inputs=size(cur_classes,1);
prob_mask=zeros(size(cur_probs));

for i=1:num_inputs
  prob_mask(i,:)=(cur_atts(i,:)==gt_value(i));
  for j=1:delta_bins
    prob_mask(i,:)=prob_mask(i,:) | ...
     (cur_atts(i,:)==gt_value(i)+j);
    prob_mask(i,:)=prob_mask(i,:) | ...
     (cur_atts(i,:)==gt_value(i)-j);
  end
end
unsorted_new_probs=cur_probs.*prob_mask;
new_probs=zeros(size(unsorted_new_probs));

for i=1:size(new_probs,1);
  [new_probs(i,:),I]=sort(unsorted_new_probs(i,:),'descend');
  new_classes(i,:)=cur_classes(i,I);
end

%Recalculate accuracy
acc=mean(new_classes(:,1)==gt_classes)
ac5=mean(gt_classes==new_classes(:,1) |...
   gt_classes==new_classes(:,2) |...
   gt_classes==new_classes(:,3) |...
   gt_classes==new_classes(:,4) |...
   gt_classes==new_classes(:,5) ...
  )
  
