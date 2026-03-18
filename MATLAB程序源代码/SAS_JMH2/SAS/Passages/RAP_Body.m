function [NErr,ed]=RAP_Body(x,data)%x为出口总温，初值x0是区间[GasIn.Tt,data.Two]中任意值
R=data.Cons.R;
gamma=data.Cons.gamma;
if data.flag==0 % data.flag=0
    Ma2=0.999;
    Ps2=data.Pb;
    Ts2=TstarMa2T(x,Ma2); %x为出口总温
elseif data.flag==1
    Ma2=0.999;
    Ps2=PstarMa2P(x(1),Ma2);
    Ts2=TstarMa2T(x(2),Ma2); 
elseif data.flag==2
    Ma2=x(1);
    Ps2=data.Pb;
    Ts2=TstarMa2T(x(2),Ma2); %出口静温
end

A=1/4*pi*(data.d2^2-data.d1^2);%环形面积

Vg2=sqrt(gamma*R*Ts2);%出口当地声速
V2=Ma2*Vg2;%出口速度
rhos2=Ps2/(R*Ts2);%出口密度
W=rhos2*V2*A;%出口流量
y1_0 = Ps2; y2_0 = V2; y3_0 = Ts2;
options = odeset('Events',@(t,y)RAP_eventfun(t,y,data));%odeset - 为 ODE 和 PDE 求解器创建或修改 options 结构体
if data.Node1.x~=data.Node2.x %=1
    xspan =linspace(data.Node2.x,data.Node1.x,data.N);%Node1=(0,0,0),Node2=(0.1,0,0)
else
    xspan = linspace(data.Node2.y,data.Node1.y,data.N);
end

F=@(x,y) funwrapper2(@RAP_Body_Body,x,y,data);%FUN=@(x,y) funwrapper2(@RAP_Body_Body,x,y,data)；FUN(x,y)=RAP_Body_Body(x,y,data)
[t,y] = ode45(F,xspan,[y1_0 y2_0 y3_0],options);%y:出口静压Ps2, 出口速度V2，出口静温Ts2 

Ma2=y(:,2)./sqrt(gamma.*R.*y(:,3));
Pt2=y(:,1).*(1+(gamma-1)/2.*Ma2.^2).^(gamma/(gamma-1));
Tt2=y(:,3).*(1+(gamma-1)/2.*Ma2.^2);
if data.flag==0%flag=0
    NErr=(Tt2(end)-data.GasIn.Tt)/data.GasIn.Tt;
elseif data.flag==1 || data.flag==2
    NErr(1)=(Pt2(end)-data.GasIn.Pt)/data.GasIn.Pt;
    NErr(2)=(Tt2(end)-data.GasIn.Tt)/data.GasIn.Tt;
end
ed.Ma=Ma2;
ed.Pt=Pt2;
ed.Ps=y(:,1);
ed.Tt=Tt2;
ed.W=W;
[~,extra]=RAP_Body_Body(t(end),y(end,:),data);
ed.Rew=extra.Rew; % ed包括出口马赫数，出口总压，出口两个node间的总温分布，流量，旋转雷诺数
end