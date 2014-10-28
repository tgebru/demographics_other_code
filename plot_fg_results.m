function plot_fg_results(det_gt_classes,det_pred_classes,title_prefix,names,classes,total_accuracy)

if nargin < 6
  names=[]
end

%Look at confusion matrix
fprintf('Confusion matrix\n')
C=confusionmat(det_gt_classes,det_pred_classes,'order',classes);

rowsum=sum(C,2);
colsum=sum(C,1);

rzero=find(rowsum==0);
colzero=find(colsum==0);
allzero=intersect(rzero,colzero);
nclasses=classes;
classes(allzero)=[];
names(allzero)=[];

C=confusionmat(det_gt_classes,det_pred_classes,'order',classes);

xticklabels=names;
xticks=linspace(1,size(C,2),numel(xticklabels));
figure,
gt_samples=sum(C,2);
Cnorm=zeros(size(C));
for i=1:size(C,1)
  Cnorm(i,:)=C(i,:)./gt_samples(i);
end
Cnorm(find(isnan(Cnorm)))=0;
imagesc(Cnorm); 
title(sprintf('%s accuracy=%s',title_prefix,total_accuracy));
colorbar;
set(gca,'XTick',xticks,'XtickLabel',xticklabels);
set(gca,'YTick',xticks,'YtickLabel',xticklabels);
xticklabel_rotate([],75,[], 'Fontsize', 12)
grid on
if (size(C,1)>20)
  grid minor
end
keyboard


% Look at accuracy by class
fprintf('Accuracy by class\n')
accuracy=diag(C)./sum(C,2);
[sorted_classes, sorted_inds]=sort(accuracy);
cnames=names(sorted_inds);

ac=accuracy(sorted_inds);
zeroinds=find(ac==0);
ac(zeroinds)=[]
cnames(zeroinds)=[];
csum=sum(C(sorted_inds,:),2);
csum(zeroinds)=[];
sorted_inds(zeroinds)=[];
zero_samples=find(csum==0);
csum(zero_samples)=[];
sorted_inds(zero_samples)=[];
ac(zero_samples)=[];
cnames(zero_samples)=[];
figure,
subplot(2,1,1)
xticks=linspace(1,numel(csum),numel(csum));
set(gca,'XTick',xticks,'XtickLabel',cnames);
xticklabel_rotate([],75,[], 'Fontsize', 12)
title(sprintf('accuracy by class %s',title_prefix))
stem(ac)
grid on
grid minor
subplot(2,1,2)
stem(csum)
grid on
grid minor
title(sprintf('number of samples by class %s',title_prefix))
xticks=linspace(1,numel(csum),numel(csum));
set(gca,'XTick',xticks,'XtickLabel',cnames);
xticklabel_rotate([],75,[], 'Fontsize', 12)

%Look at number of samples after removing zero samples
num_samples=sum(C,2);
num_samples(find(num_samples==0))=[];
figure,
hist(num_samples,100)
title('Number of samples')
grid on
grid minor

%Zoom into classes with zero accuracy
fprintf('Zero accuracy\n')
accuracy=diag(C)./sum(C,2);
zeroinds=find(accuracy==0);
figure,
subplot(2,1,1)
znames=names(zeroinds);
xticks=linspace(1,numel(znames),numel(znames));
set(gca,'XTick',xticks,'XtickLabel',znames);
if ~isempty(xticks)
  xticklabel_rotate([],75,[], 'Fontsize', 12)
end
stem(accuracy(zeroinds));
grid on
grid minor
subplot(2,1,2)
num_samples=sum(C,2);
stem(num_samples(zeroinds));
title('zero accuracy')
grid on
grid minor
xticks=linspace(1,numel(znames),numel(znames));
set(gca,'XTick',xticks,'XtickLabel',znames);
if ~isempty(xticks)
  xticklabel_rotate([],75,[], 'Fontsize', 12)
end

