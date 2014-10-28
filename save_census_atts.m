%Database parameters
dbname='demo';
username='tgebru';
password='';
driver='com.mysql.jdbc.Driver';
dburl = ['jdbc:mysql://localhost:3306/' dbname];
javaclasspath('/imagenetdb/tgebru/cars/demographics/boston_cars/code/mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar');
  conn = database(dbname, username, password, driver, dburl);
fdata=textscan(fopen('acs_var_names.txt',...
    'r'),'%s\n');
census_vars=fdata{1};

%Load data
fprintf('Loading data\n')
val_save_name='gsv_val.mat'
train_save_name='gsv_train.mat'

%train_data=load(train_save_name);
val_data=load(val_save_name);
%train_images=train_data.images;
val_images=val_data.val_images;

num_train_ims=numel(train_images);
for i=1:num_train_ims
  if isempty(train_images(i).census)
    fprintf('Getting data for training %d out of %d\n',i,num_train_ims);
    train_images(i).census=get_census_data(train_images(i).im_fname,conn,census_vars);
  end
end

num_val_ims=numel(val_images);
for i=1:num_val_ims
  if isempty(val_images(i).census)
    fprintf('Getting data for validation %d out of %d\n',i,num_val_ims);
    val_images(i).census=get_census_data(val_images(i).im_fname,conn,census_vars);
  end
end

train_data.images=train_images;
val_data.images=val_images;
save(val_save_name,'val_images');
save(train_save_name,'train_images');

