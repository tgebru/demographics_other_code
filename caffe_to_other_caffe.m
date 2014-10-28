gsv_train_orig = 'webgsv_det_train.txt';
gsv_val_orig = 'webgsv_det_val.txt';


% Make
%new_train = 'webgsv_det_train_make.txt';
%new_val = 'webgsv_det_val_make.txt';
%ctm = class_to_makeid_map();
%fdata = textscan(fopen(gsv_val_orig, 'r'), '%s %d %s\n', 'delimiter', {' '});
%f = fopen(new_val, 'w');
%for i = 1:numel(fdata{1})
%  fprintf(f, '%s %d %s\n', fdata{1}{i}, ctm(double(fdata{2}(i))), fdata{3}{i});
%end
%fclose(f);
%fdata = textscan(fopen(gsv_train_orig, 'r'), '%s %d %s\n', 'delimiter', {' '});
%f = fopen(new_train, 'w');
%for i = 1:numel(fdata{1})
%  fprintf(f, '%s %d %s\n', fdata{1}{i}, ctm(double(fdata{2}(i))), fdata{3}{i});
%end
%fclose(f);


% submodel
new_train = 'webgsv_det_train_submodel.txt';
new_val = 'webgsv_det_val_submodel.txt';
cts = class_to_submodelid_map();
fdata = textscan(fopen(gsv_val_orig, 'r'), '%s %d %s\n', 'delimiter', {' '});
f = fopen(new_val, 'w');
for i = 1:numel(fdata{1})
  fprintf(f, '%s %d %s\n', fdata{1}{i}, cts(double(fdata{2}(i))), fdata{3}{i});
end
fclose(f);
fdata = textscan(fopen(gsv_train_orig, 'r'), '%s %d %s\n', 'delimiter', {' '});
f = fopen(new_train, 'w');
for i = 1:numel(fdata{1})
  fprintf(f, '%s %d %s\n', fdata{1}{i}, cts(double(fdata{2}(i))), fdata{3}{i});
end
fclose(f);
