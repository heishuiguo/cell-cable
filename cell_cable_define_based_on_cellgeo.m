%smoothed cell body for get cell edge cable.original cell body for cell threshold
clear;
load WholeMovieData.mat

orig_pic=imread('cell pic.tif');
Gau= fspecial('gaussian', [5 5], 3);%for blur original pic
orig_pic_gau = imfilter(orig_pic,Gau,'same');
cut_short_cable=5;%!! parameter,enter!!for fine small cable sections
windowSize = 28;%!!parameter,enter!!for smooth edge,integer you want that's more than 1


[row1,col1]=size(orig_pic); %picture size
cell_body_o=boundaries{1}; %boundaries come from .mat file
cell_body=boundaries{1};
cell_body=round(cell_body);%cell body coordinate
%connect points of protrusion point
%for more than one protrusion,find it's index,connect
gapdis=pdist2(cell_body_o([1:end-1],:),cell_body_o([2:end],:));
dis_between_point=diag(gapdis);

protr_ind=find(dis_between_point>=6);%£¡£¡£¡distance bigger than this value is protrusion gap

protr_num=length(protr_ind);%protrusion amount
flip_protr_ind=flip(protr_ind);%add protrusion edge to cell_body from back to front
edge_pro_ind=zeros(size(cell_body_o,1),1);%matrix ready for protrusion index
%creat new cell body,where gaps bwtween two protrusin roots were connected
new_cell_body=cell_body;
new_edge_pro_ind_1=edge_pro_ind;
%new_edge_pro_ind_b=edge_pro_ind;
for i=1:length(flip_protr_ind)
    i_point=flip_protr_ind(i);
    endpoint=cell_body(i_point+1,:)
    firstpoint=cell_body(i_point,:)
    [xc,yc]=Cooline(endpoint(1),firstpoint(1),endpoint(2),firstpoint(2));%protrusion edge
    protrusion_edge1=flipud([xc yc]);
    protrusion_edge2=protrusion_edge1;
    protrusion_edge2([1,end],:)=[];
    new_cell_body=[new_cell_body(1:i_point,:); protrusion_edge2; new_cell_body(i_point+1:end,:)];%!!new cell body
    xz=protrusion_edge2(:,1)*0+1;%index,show protrusion location use 1.and 0 means edge.
    new_edge_pro_ind_b=new_edge_pro_ind_1;
    new_edge_pro_ind_1=[new_edge_pro_ind_1(1:i_point);xz; new_edge_pro_ind_1(i_point+1:end)];
end
new_edge_pro_ind_2=logical(new_edge_pro_ind_1);

%creat a pic with boundary,get cell body,use roipoly
cell_1=zeros(row1,col1);
cell_body1a = roipoly(cell_1,cell_body_o(:,2),cell_body_o(:,1));
%1 smooth edge
kernel = ones(windowSize) / windowSize ^ 2;
blurryImage0 = conv2(single(cell_body1a), kernel, 'same');
cell_body2 = blurryImage0 > 0.5; % Rethreshold
%figure,imshow(cell_body2)
%smooth edge but keep edge sunken
cell_body3=imsubtract((cell_body1a),(cell_body2));
cell_body4=imsubtract(cell_body1a,imbinarize(cell_body3));
figure,imshow(cell_body4) %cell_body4 is smoothed cell,use this one
%cell_body5=cell_body4;%for iteration downbelow
%3 creat triangle threshold by click on pic,cell centre is one of corners
cen=regionprops(cell_body4,'Centroid');
cell_centre = cat(1,cen.Centroid);
%set color at here
figure,imshow(imadjust(orig_pic))
hold on
plot(new_cell_body(:,2),new_cell_body(:,1));
protr_ind=new_cell_body(new_edge_pro_ind_2,:);%plot protrusion cut
plot(protr_ind(:,2),protr_ind(:,1),'.');%plot protrusion cut
plot(new_cell_body(1,2),new_cell_body(1,1),'*r');%plot beginning and ending
%click
[dot_x,dot_y] = ginput;
points_all=[dot_y,dot_x];%attention,x and y
dist1_all = pdist2(points_all,new_cell_body);
[mixva,minind]=min(dist1_all,[],2);%minind is hand dot index
dot_ind=minind;
%cable_poindx1=[(protr_ind_now+1);minind;protr_ind_sec]
figure(10),imshow(imadjust(orig_pic_gau));hold on;
for l=1:(length(points_all)/2) %hand dotted short cables,inner cell amount
    %2 store each edge,dipend on how many pixel shrink
    shri_eg=inputdlg('a','b',[1 30],{'5'});
    shrink_eg_pix=shri_eg{1};
    shrink_eg_pix=str2num(shrink_eg_pix);
    edge_store_in_cell={};
    roi_edge_biggest_all=[];%for intensity value
    cell_body5=cell_body4;
    for j=1:shrink_eg_pix %store each shrink into centre cables
        edge_store1=bwmorph(cell_body5,'remove');
        edge_store_in_cell{j}=edge_store1;
        cell_body5=cell_body5-edge_store1;
        %yanzheng
    end
    %yanzheng
    %[edge_ind_yanzheng_r,edge_ind_yanzheng_c]=find(edge_store_in_cell{j})
    %figure,imshow(imadjust(orig_pic));hold on;plot(edge_ind_yanzheng_c,edge_ind_yanzheng_r,'.')
    p_a=dot_ind(l*2-1);
    p_b=dot_ind(l*2);
    if p_a>p_b
        cable_poindx_short=[([p_a:size(new_cell_body,2)]),1:p_b];
    else
        cable_poindx_short=[p_a:p_b];
    end
    % 6,divide hand dotted edge into several piece,get several threshold roi area,then will get a fine cable
    cell_body_n_cable_current=new_cell_body(cable_poindx_short,:);
    length_cable_current=size(cell_body_n_cable_current,1);
    cut_thrd_ind=1:cut_short_cable:length_cable_current;
    %verify
    %figure(9),imshow(imadjust(orig_pic_gau));hold on;
    %plot(cell_body_n_cable_current(:,2),cell_body_n_cable_current(:,1))
    roi_edge_big_ind_all=[]
    roi_edge_big_ind_all=[]
    for n=1:length(cut_thrd_ind)-1  % for small piece of short cable,fine cable
        small_cable_poindx=[cut_thrd_ind(n):cut_thrd_ind(n+1)];
        roi_area = roipoly(cell_body1a,[cell_body_n_cable_current(small_cable_poindx,2);cell_centre(1)],[cell_body_n_cable_current(small_cable_poindx,1);cell_centre(2)]);
        thresh_pic{l}=roi_area;
        %yanzheng
        %figure(11),imshow(roi_area);hold on
        %4,get cable_line,threshold plus shrink edges
        roi_edge_ind_all={};
        roi_edge_val_all_mean_and_amount=[];%?? roi_edge_big_ind_all
        for m=1:shrink_eg_pix %edges in one cable
            roi_edge=roi_area.*edge_store_in_cell{m};
            [roi_edge_r,roi_edge_c]=find(roi_edge); %for plot
            roi_edge_ind_all{m}=[roi_edge_r,roi_edge_c]; %!!!for plot,all roi edge,check if it need to be empty
            roi_edge_val=uint16(roi_edge).*orig_pic_gau;%£¡£¡£¡ %real original pic plus with roi edge
            roi_edge_val_nzero_ind=find(roi_edge_val);
            roi_edge_val_nzero=roi_edge_val(roi_edge_val_nzero_ind);%real original pixels value of this small edge
            roi_edge_val_mean=mean(roi_edge_val_nzero(:));
            roi_edge_val_mean_amount=length(roi_edge_val_nzero)
            roi_edge_val_all_mean_and_amount(m,:)=[roi_edge_val_mean,roi_edge_val_mean_amount];%?? %mean and amount of small edge pixel is for calculation later
            %plot(roi_edge_c,roi_edge_r,'.') %each small edges of a small cable
        end
        %5,get biggest roi edge sum,choose it
        [roi_edge_biggest,biggest_ind]=max(roi_edge_val_all_mean_and_amount(:,1));
        roi_edge_biggest_all(n,:)=roi_edge_val_all_mean_and_amount(biggest_ind,:); %all short cable's brightest edge mean and pixel amount,for calculate
        roi_edge_big_ind=roi_edge_ind_all{biggest_ind}; %!!!check roi_edge_ind_all,choosed brightest small edge
        %hold on;plot(roi_edge_big_ind(:,2),roi_edge_big_ind(:,1),'.')
        roi_edge_big_ind_all=[roi_edge_big_ind_all;roi_edge_big_ind];%?? each brightest small edge pixel index,concatenate to a dotted cable
        roi_edge_big_ind_all1=roi_edge_big_ind_all;
    end
    roi_edge_big_ind_all_all{l}=roi_edge_big_ind_all1;
    roi_edge_biggest_all_cable{l}=roi_edge_biggest_all; %data,column 1 is one small shrink edge's mean intensity,column 2 is it's pixel amount
    hold on;plot(roi_edge_big_ind_all1(:,2),roi_edge_big_ind_all1(:,1),'.','MarkerSize',20)
    %roi_edge_big_ind_all=[];
end

%get cable index pic
cell_2=cell_1; %empty pic
%cell_3=cell_1;
short_cable_ind1=[]
short_cable_ind2
for p=1:length(roi_edge_big_ind_all_all)
    short_cable_ind=roi_edge_big_ind_all_all{p};
    short_cable_ind1=[short_cable_ind1;short_cable_ind]
end
    


    %save data
    linear_short=sub2ind(size(cell_2),short_cable_ind1(:,1),short_cable_ind1(:,2));
    cell_2(linear_short)=1;
    figure,imshow(imadjust(cell_2))
    
    
    %connect gaps
    Gau= fspecial('gaussian', [7 7], 7);%for blur original pic
    cell_3 = imfilter(cell_2,Gau,'same');
    cell_4=imbinarize(cell_3);
    figure,imshow(cell_4)
    
    %test connect points
    short_cable_ind2=short_cable_ind1;
    
    
    
for o=1:(length(points_all)/2)
    cur_cable=roi_edge_biggest_all_cable{o};
    sum_cur_cables=cur_cable(:,1).*cur_cable(:,2);
    all_cur_cable=sum(sum_cur_cables);
    all_cables_intensity(o)=all_cur_cable;
    all_cables_amount(o)=sum(cur_cable(:,2));
end

all_big_cable_intensity=sum(all_cables_intensity)
all_big_cable_amount=sum(all_cables_amount)
A={'hole cable mean intensity','hole cable length','short cable mean intensity','short cable length'}
xlswrite('cable result.xlsx',A,1,'b2')
xlswrite('cable result.xlsx',[all_big_cable_intensity,all_big_cable_amount],1,'b3')
xlswrite('cable result.xlsx',[all_cables_intensity',all_cables_amount'],1,'d3')
    
    
    
