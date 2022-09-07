%%
clear
[file,path] = uigetfile('*') %usually is seg_255_0.tif
cd(path)
finfo=imfinfo(file);
k=length(finfo)
for i=1:k
    a1=imread(file,'index',i);
    a2=imbinarize(a1);
    a3=bwareafilt(a2,1);
    a3=imfill(a3,'holes');
    measurements = regionprops(a3, 'Centroid');
    centroid = measurements.Centroid;
    centroid_all(i,:)=centroid;
end
ar1=centroid_all([1:end-1],:);
ar2=centroid_all([2:end],:);
ds2=pdist2(ar1,ar2);
ds3=diag(ds2);%distance of each point with it's second point
ds_long=pdist2(centroid_all(1,:),centroid_all(end,:));
xlname=strcat(file,'.xlsx');
writecell({'each timepoint distance','','','distance of first between last'},xlname)
writematrix(ds3,xlname,'sheet',1,'range','a2')
writematrix(ds_long,xlname,'sheet',1,'range','d2')


