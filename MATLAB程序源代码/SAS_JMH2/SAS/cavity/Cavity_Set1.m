function [Geo,boundary]=Cavity_Set1(data)% BC.Td=800,N=2;
x=data.x;y=data.y;N=data.N;node=data.node;
%% 给定边界条件
tot=length(x);
type=5*ones(tot);%指定边界类型,默认为流体面5

boundary.type=[1,5,0,5]; % 0静止壁面 1旋转壁面 5流体面
boundary.wall_type=[1,NaN,1,NaN];%壁面结构类型：1：disk；2：cylinder；3：cone；
if ismember(2,boundary.wall_type)
    boundary.Rh=25e-3; % 柱面所在半径位置
    boundary.Lh=1e-3; % 柱面长度
else
    boundary.Rh=[];
end
boundary.RES=[data.RES,NaN,0,NaN];
boundary.htt=[0,NaN,0,NaN]; % heat transfer type: 0：给定热流；1: 给定壁面温度；
%静止壁面边界给定壁面温度，旋转壁面边界给定热流
boundary.q=[data.q,NaN,data.q,NaN];%热流密度，绝热=0
boundary.Tw=[data.Tw,NaN,NaN,NaN];%壁面温度
boundary.roughness=[1e-5,NaN,1e-5,NaN];%粗糙度
%% 划分网格
if isempty(N) %N为[]时，isempty(N)=1，否则为0；
    N=length(node)+1;
end
xmin=min(x);xmax=max(x);
ymin=min(y);ymax=max(y);
PosL=min(y); %低位半径
PosH=max(y); %高位半径
if isempty(node)
    y_s=linspace(ymin,ymax,N+1);% 等分为N个控制体
else
    y_s=[ymin node ymax];
end
y_s(1)=[];y_s(end)=[]; % 新划分的网格线的y坐标
x(end+1)=x(1);
y(end+1)=y(1);
x_s=[];%x方向不划分
jj=0;count=[];
for i=1:length(y_s) % i：当前控制体；从入口开始计算每个控制体
    flag=0;n=0;point=[];
    for j=1:length(x)-1 % j:控制体的当前顶点，循环计算几何模型的各个顶点
        if (y(j)>=y_s(i) && y(j+1)<=y_s(i)) || (y(j)<=y_s(i) && y(j+1)>=y_s(i))
            if x(j)==x(j+1)
                if size(x_s,1)==i-1
                    x_s(i,1)=x(j); % 新划分的网格线的x坐标：x_s
                    point1=[x_s(i,1),y_s(i)]; % 控制体右上角node
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
        if (i~=1 && y(j)<=y_s(i) && y(j)>=y_s(i-1))
            n=n+1;
            point(n,:)=[x(j),y(j)];
            flag=1;
            jj=jj+1;
            count(jj)=i;
        end
    end
    %
    if i==1 % 最下方控制体（1）
        face{i,1}=point1; %右上角点
        face{i,2}=point2; %右下角点
        face{i,3}=point3; %左下角点
        face{i,4}=point4; %左上角点
    elseif flag==1 %非矩形控制体
        face{i,1}=point1; %右上角点
        face{i,2}=face{i-1,1}; %右下角点
        face{i,3}=face{i-1,4}; %左下角点
        for m=1:n
            face{i,3+m}=point(m,:);
        end
        face{i,4+n}=point4; %左上角点
    else% 中间控制体
        face{i,1}=point1; %右上角点
        face{i,2}=face{i-1,1}; %右下角点
        A=cell2mat(face(i-1,:));
        point3=A(end-1:end);
        face{i,3}=point3; %左下角点
        face{i,4}=point4; %左上角点
    end
end
%添加最后一个面
y(end)=[];
x(end)=[];
[~,i_m]=maxk(y,2); % i_m=[1,4] maxk返回y数组2个最大的元素索引
if x(i_m(1))>x(i_m(2)) % 让右上角点为point1，左上角点为point4
    point1=[x(i_m(1)),y(i_m(1))];% 右上角点
    point4=[x(i_m(2)),y(i_m(2))];% 左上角点
else
    point1=[x(i_m(2)),y(i_m(2))];
    point4=[x(i_m(1)),y(i_m(1))];
end
face{i+1,1}=point1; % 最上方控制体
face{i+1,2}=face{i,1};
id=length(cell2mat(face(i,:)))/2;
face{i+1,3}=face{i,id};
face{i+1,4}=point4; % face储存各控制体的四个顶点坐标

% 计算与x轴的夹角
for i=1:size(face,1)
    l=length(cell2mat(face(i,:)))/2;
    for j=1:l
        if j~=l
            theta(i,j)=abs(l_angle(face{i,j},face{i,j+1}));
        else
            theta(i,j)=abs(l_angle(face{i,j},face{i,1}));
        end
    end
end
% 控制体线
if data.direction == 1 % data.direction:1从下至上，-1为从上至下
    y_k=[ymin y_s ymax];
elseif data.direction == -1
    y_k=[ymax flip(y_s) ymin];
    face=flip(face);
end
%% 绘图
x(end+1)=x(1);
y(end+1)=y(1);
if data.ifplot==1 % 绘制盘腔控制体
    %subplot(1,2,1)
    plot(x,y,'Linewidth',1.5,'Color','b') % 绘制盘腔几何
    hold on
    for k=1:length(y_s) % 绘制中间N-1个网格线
        plot(x_s(k,:),[y_s(k) y_s(k)])
    end
    xlabel('m');ylabel('m');
    set(gca,'FontSize',15);
    axis equal
    %{
    subplot(1,2,2)
    for i=1:size(face,1)
        if i~=count
            for ii=1:4
                x_mesh(i,ii)=face{i,ii}(1);
                y_mesh(i,ii)=face{i,ii}(2);
            end
            x_mesh(i,ii+1)=x_mesh(i,1);
            y_mesh(i,ii+1)=y_mesh(i,1);
            plot(x_mesh(i,:),y_mesh(i,:),'Linewidth',1.5,'Color','b')
            hold on
        else
            l=length(cell2mat(face(i,:)))/2;
            for ii=1:l
                x_mesh1(i,ii)=face{i,ii}(1);
                y_mesh1(i,ii)=face{i,ii}(2);
            end
            x_mesh1(i,ii+1)=x_mesh1(i,1);
            y_mesh1(i,ii+1)=y_mesh1(i,1);
            plot(x_mesh1(i,[1:l+1]),y_mesh1(i,[1:l+1]),'Linewidth',1.5,'Color','b')
            hold on
        end
    end
    xlabel('m');ylabel('m');
    set(gca,'FontSize',15);
    axis equal
    %}
end

%CerrC(type,htt,Tf,tH,roughness);%检查盘腔参数是否设置正确
%% output

Geo.face=face;
Geo.theta=theta;
Geo.G=max(x)-min(x);%间隙
Geo.y_k=y_k;
%Geo.y_s=y_s;
Geo.PosL=PosL;
Geo.PosH=PosH;
Geo.N=N; % Geo划分控制体
end