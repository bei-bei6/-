function [ax,hlines] = plotyyyy(x1,y1,x2,y2,x3,y3,x4,y4,ylabels)
figure('units','normalized',...
       'DefaultAxesXMinorTick','on','DefaultAxesYminorTick','on');
[ax,hlines(1),hlines(2)] = plotyy(x1,y1,x2,y2);
cfig = get(gcf,'color');%当前图片的背景颜色？
% pos = [0.1  0.1  0.7  0.8];%[坐下角横坐标，左下角纵坐标，图像宽度，图像高度]注意都是相对值
% offset = pos(3)/5.5;
% pos(3) = pos(3) - offset/2;
pos=[0.2  0.1  0.6  0.8];
set(ax,'position',pos); %重新调整位置 
pos3=[0.1 pos(2) pos(3)+0.2 pos(4)];%另外两个框
limx1=get(ax(1),'xlim');%获取当前x范围
limx3=[limx1(1)-(limx1(2)-limx1(1))/6 limx1(2)+(limx1(2)-limx1(1))/6];%向两侧拓展
limx4=[limx1(1)-(limx1(2)-limx1(1))/6 limx1(2)+(limx1(2)-limx1(1))/6];%向两侧拓展
ax(3)=axes('Position',pos3,'box','off',...
   'Color','none','XColor','k','YColor','k',...   
   'xtick',[],'xlim',limx3,'yaxislocation','left');
ax(4)=axes('Position',pos3,'box','off',...
   'Color','none','XColor','k','YColor','r',...   
   'xtick',[],'xlim',limx4,'yaxislocation','right');
hlines(3) = line(x3,y3,'Color','k','Parent',ax(3));%绘制第三条曲线
hlines(4) = line(x4,y4,'Color','r','Parent',ax(4));%绘制第四条曲线
limy3=get(ax(3),'YLim');
line([limx1(2) limx3(2)],[limy3(1) limy3(1)],...
   'Color',cfig,'Parent',ax(3),'Clipping','off');
% axes(ax(2))
set(get(ax(1),'ylabel'),'string',ylabels{1})
set(get(ax(2),'ylabel'),'string',ylabels{2})
set(get(ax(3),'ylabel'),'string',ylabels{3})
set(get(ax(4),'ylabel'),'string',ylabels{4})