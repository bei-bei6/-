function Geo=TDC(N,x,y,node,PosI,PosO,boundary,ifplot)

if isempty(N)
    N=length(node)+1;
end

type=boundary.type;
htt=boundary.htt;
Tf=boundary.Tf;
tH=boundary. tH;
roughness=boundary.roughness;

x(end+1)=x(1);
y(end+1)=y(1);
xmin=min(x);xmax=max(x);
ymin=min(y);ymax=max(y);

if isempty(node)
    y_s=linspace(ymin,ymax,N+1);
else
    y_s=[ymin node ymax];
end
y_s(1)=[];y_s(end)=[];
x_s=[];
for i=1:length(y_s)
    for j=1:length(x)-1
        if (y(j)>=y_s(i) && y(j+1)<=y_s(i)) || (y(j)<=y_s(i) && y(j+1)>=y_s(i))%点在线段上，求x坐标
            if x(j)==x(j+1)%垂直
                if size(x_s,1)==i-1
                    x_s(i,1)=x(j);
                    point1=[x_s(i,1),y_s(i)];
                    point2=[x(j+1),y(j+1)];
                else
                    x_s(i,2)=x(j);
                    point3=[x(j),y(j)];
                    point4=[x_s(i,2),y_s(i)];
                end
            else
                k=(y(j+1)-y(j))/(x(j+1)-x(j));
                b=y(j)-k*x(j);
                if size(x_s,1)==i-1
                    x_s(i,1)=(y_s(i)-b)/k;
                    point1=[x_s(i,1),y_s(i)];
                    if i==1 % 非内部节点(第一个面)有可能出现多边形
                        y_n=y(y<y_s(i));
                        x_n=x(y<y_s(i));
                        [~,miny2p]=mink(y_n,2);
                        if x_n(miny2p(1))>x_n(miny2p(2))
                            point2=[x_n(miny2p(1)),y_n(miny2p(1))];
                        else
                            point2=[x_n(miny2p(2)),y_n(miny2p(2))];
                        end
                    end
                else
                    x_s(i,2)=(y_s(i)-b)/k;
                    point4=[x_s(i,2),y_s(i)];
                    if i==1% 非内部节点(第一个面)有可能出现多边形
                        y_n=y(y<y_s(i));
                        x_n=x(y<y_s(i));
                        [~,miny2p]=mink(y_n,2);
                        if x_n(miny2p(1))<x_n(miny2p(2))
                            point3=[x_n(miny2p(1)),y_n(miny2p(1))];
                        else
                            point3=[x_n(miny2p(2)),y_n(miny2p(2))];
                        end
                    end
                end
            end
        end
    end
    if i==1
        face{i,1}=point1;
        face{i,2}=point2;
        face{i,3}=point3;
        face{i,4}=point4;
    else
        face{i,1}=point1;
        face{i,2}=face{i-1,1};
        face{i,3}=face{i-1,4};
        face{i,4}=point4;
    end
    
end
%添加最后一个面
y(end)=[];
x(end)=[];
[~,i_m]=maxk(y,2);
if x(i_m(1))>x(i_m(2))
    point1=[x(i_m(1)),y(i_m(1))];
    point4=[x(i_m(2)),y(i_m(2))];
else
    point1=[x(i_m(2)),y(i_m(2))];
    point4=[x(i_m(1)),y(i_m(1))];
end
face{i+1,1}=point1;
face{i+1,2}=face{i,1};
face{i+1,3}=face{i,4};
face{i+1,4}=point4;
% 计算与y轴的夹角
for i=1:size(face,1)
    for j=1:4
        if j~=4
            theta(i,j)=abs(l_angle(face{i,j},face{i,j+1}));
        else
            theta(i,j)=abs(l_angle(face{i,j},face{i,1}));
        end
    end
end
x(end+1)=x(1);
y(end+1)=y(1);
if ifplot==1
%     figure(2)
    subplot(1,2,1)
    plot(x,y,'Linewidth',1.5,'Color','b')
    hold on
    for k=1:length(y_s)
        plot(x_s(k,:),[y_s(k) y_s(k)])
    end
    xlabel('m');ylabel('m');
    set(gca,'FontSize',15);
    axis equal
    %
    subplot(1,2,2)
    for i=1:size(face,1)
        for ii=1:4
            x_mesh(i,ii)=face{i,ii}(1);
            y_mesh(i,ii)=face{i,ii}(2);
        end
    end
    x_mesh(:,end+1)=x_mesh(:,1);
    y_mesh(:,end+1)=y_mesh(:,1);
    for i=1:size(face,1)
        plot(x_mesh(i,:),y_mesh(i,:),'Linewidth',1.5,'Color','b')
        hold on
    end
    
    xlabel('m');ylabel('m');
    set(gca,'FontSize',15);
    axis equal
end

CerrC(type,htt,Tf,tH,roughness);%检查盘腔参数是否设置正确

% Geo.boundary=boundary;
Geo.face=face;
Geo.theta=theta;

Geo.y_s=y_s;
Geo.PosI=PosI;
Geo.PosO=PosO;
Geo.N=N;
end