function [GasOut,ed]=Cavity(GasIn,Pb,data)
%该程序可以计算一般腔的可压缩腔流动
%{
if Pb-GasIn.Pt>1e-3
    disp('腔单元发生逆流')
    [GasIn,Pb]=swap(GasIn,Pb);
    adverse=-1;
elseif abs(Pb-Pt1)<=1e-3
    GasOut.W=0;
    ed=[];
    return;  %不再向下执行Cavity函数
else
    adverse=1;
end
%}
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

data.GasIn=GasIn;
data.Pb=Pb;
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;

count_rotwall=sum(data.boundary.type==1) ; % 旋转壁面边界总数
data.omega_ref=max(abs(data.boundary.RES))*2*pi/60; % 参考转子角速度,rad/s

if data.direction == 1 % data.direction:1从下至上，-1为从上至下
    data.Rin=data.Geo.PosL; % 入口半径
    data.Rout=data.Geo.PosH; % 出口半径
    data.AI=2*pi*data.Geo.PosL*data.Geo.G; % 入口面积
    data.AO=2*pi*data.Geo.PosH*data.Geo.G; % 出口面积
elseif data.direction == -1
    data.Rin=data.Geo.PosH; % 入口半径
    data.Rout=data.Geo.PosL; % 出口半径
    data.AI=2*pi*data.Geo.PosH*data.Geo.G; % 入口面积
    data.AO=2*pi*data.Geo.PosL*data.Geo.G; % 出口面积
end
%% 计算流量初值 （ideal condition:绝能等熵流 Tt1=Tt2 Pt1=Pt2）
% 判断流动状态【待修改】
% flowdirection=cp/R*log(Ts2/Ts1)-log(Ps2/Ps1);%flowdirection>0,正向流动
PI=Pt1/Pb; %落压比：进口总压与反压之比
PI_cr=((gamma+1)/2)^(gamma/(gamma-1));%临界压比，空气(k=1.4) Pt/Pcr=1.8929
P_cr=Pt1/PI_cr; %临界压力
if PI < PI_cr %亚临界流动状态
    data.choke=0; %未壅塞
%     disp('腔单元亚临界')
    Ps2=Pb;
    Ts2=Tt1/(Pt1/Ps2)^((gamma-1)/gamma);
    Ma2=TstarT2Ma(Tt1,Ts2);
else PI >= PI_cr %临界及超临界流动状态
    data.choke=1; %壅塞
%     fprintf('%s\n','腔出口壅塞')
    Ps2=P_cr;
    Ma2=1;
    Ts2=TstarMa2T(Tt1,Ma2);
end
rhos2=Ps2/(R*Ts2);
c2=sqrt(gamma*R*Ts2);
V2=Ma2*c2;
W_max=rhos2*V2*data.AO;%最大流量？【】
%
if isfield(GasIn,'W')
    W0=GasIn.W;
elseif data.omega_ref ~=0
    W0= count_rotwall*0.219*mu*data.Geo.PosH*(rhos2*data.Geo.PosH^2*data.omega_ref/mu)^0.8; %最大流量：自由盘泵送质量流量
    %W0=0.22811492;
else
    W0 = W_max;
end
data.Ps2=Ps2;
%%
opt.maxiter=500;
opt.tolfun=1e-6;
opt.tolx=1e-12;
icount=1;imax=1000;
while 1
    x0=W0;
    bounds=[0 2*W_max];
    Cell=@Cavity_Body1;
    FUN=@(x) funwrapper(Cell,x,data);
    try
        [W, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            W=round(W,10);
            fprintf('%s%d%s\n','Cavity模块计算已收敛, 共计',icount,'次(^_^)')
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('Cavity模块计算未收敛..., 需要Debug...(o_o)')
    end
end
[Nerr,ed]=Cavity_Body1(W,data);
%% 输出参数
GasOut.W=W;
GasOut.Tt=ed.Tt2; %Tt1=Tt2（绝能流动总温守恒）
GasOut.Ps=ed.Ps2;
GasOut.Pt=ed.Pt2;
GasOut.Ts=ed.Ts2;
GasOut.Sf=ed.Sf2;
GasOut.Swirl=ed.Swirl2;%涡参数 Swirl=omega_air*r^2
end