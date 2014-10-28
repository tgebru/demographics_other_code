function vector=map_to_vector(input_map)

num_classes=numel(input_map.keys());
vector=zeros(num_classes,1);
for i=1:num_classes
  vector(i)=input_map(i-1);
end
