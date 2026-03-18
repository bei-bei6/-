function [GasOut,ed]=Duct(GasIn,Pb,data)
%该程序可以计算变面积、摩擦、传热、旋转的可压缩管道流动
if Pb-GasIn.Pt>1e-3
    disp('管道单元发生逆流')
    [GasIn,Pb]=swap(GasIn,Pb);
    adverse=-1;
elseif abs(Pb-GasIn.Pt)<=1e-3
    GasOut.W=0;
    ed=[];
    return;  %不再向下执行Duct函数
else
    adverse=1;
end
CaseOpt=data.CaseOpt;
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
%Pr=data.Cons.Pr;

data.GasIn=GasIn;
data.Pb=Pb;
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;
if data.CaseOpt.A == 1
    data.D=(data.D1+data.D2)/2; % average diameter
    data.A1=pi/4*data.D1^2;
    data.A2=pi/4*data.D2^2;
    data.A=pi/8*(data.D1^2+data.D2^2); % average area
    data.Aw=pi*(data.D1/2+data.D2/2)*sqrt(data.L^2+(data.D2/2-data.D1/2)^2);%管道侧表面积
else
    data.A=pi/4*data.D^2;
    data.A1=data.A; data.A2=data.A;
    data.Aw=pi*data.D*data.L;%管道侧表面积
end
%% 计算流量初值 （最大流量：等熵流动，出口马赫数为1）
% 判断流动状态
PI=Pt1/Pb; %落压比：进口总压与反压之比
PI_cr=((gamma+1)/2)^(gamma/(gamma-1));%临界压比，空气(k=1.4) Pt/Pcr=1.8929
P_cr=Pt1/PI_cr; %临界压力
if PI < PI_cr %亚临界流动状态
    data.choke=0; %未壅塞
    disp('Duct单元亚临界')
    Ps2=Pb;
    Ts2=Tt1/(Pt1/Ps2)^((gamma-1)/gamma);
    Ma2=TstarT2Ma(Tt1,Ts2);
else PI >= PI_cr %临界及超临界流动状态
    data.choke=1; %壅塞
    fprintf('%s\n','Duct出口壅塞')
    Ps2=P_cr;
    Ma2=1;
    Ts2=TstarMa2T(Tt1,Ma2);
end
Pt2=PMa2Pstar(Ps2,Ma2);
rhos2=Ps2/(R*Ts2);
c2=sqrt(gamma*R*Ts2);
V2=Ma2*c2;
W_id=rhos2*V2*data.A2;%理想流量（等熵流动）
W=W_id;
W_max=Ps2*data.A2*sqrt(gamma*((gamma+1)/2))/sqrt(R*Tt1); %最大流量（等熵流动，出口马赫数为1）
data.Ps2=Ps2;
%%
opt.maxiter=2000;
opt.tolfun=1e-10;
opt.tolx=1e-10;
icount=1;imax=1000;
while 1
    x0=rand;% Ma1
    bounds=[0 1];
    Cell=@Duct_Body;
    FUN=@(x) funwrapper(Cell,x,data);
    try
        [x, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))%ithist.normf：函数误差（NErr）
            icount=icount+1;
        else
            x=round(x,10);
            fprintf('%s%d%s\n','Duct模块计算已收敛, 共计',icount,'次(^_^)')
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('Duct模块计算未收敛..., 需要Debug...(o_o)')
    end
end
[Nerr,ed]=Duct_Body(x,data);
%%
if data.RES==0
    V_phi1=ed.V1*sin(pi/2-data.beta);%切向速度
else
    V_phi1=(data.RES*2*pi/60)*data.r1*0.5;%切向速度
end
Re1=W*data.D/(mu*data.A1); % Re1=rhos1*V1*D/mu;
Cd=CdCalc(Re1,data.rf,data.D,data.L,Pt1,Ps2,ed.V1,V_phi1,data.beta,data.theta0); %流量系数
W=Cd*W; %实际流量
%% 输出参数
GasOut.W=adverse*W*data.Num;
GasOut.Tt=ed.Tt2; %Tt1=Tt2（绝能流动总温守恒）
GasOut.Ps=ed.Ps2;
GasOut.Pt=ed.Pt2;
GasOut.Ts=ed.Ts2;
GasOut.Swirl=GasIn.Swirl;%涡参数 Swirl=omega_air*r^2
end