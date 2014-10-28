function im=put_in_caffe_form(im)

% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im=im(:,:,[3 2 1]);

%Caffe is column major
im=permute(im,[2,1,3]);
