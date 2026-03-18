function [GasOut,ed]=Hole(GasIn,Pb,data)
%% ideal condition:绝能等熵流 Tt1=Tt2 Pt1=Pt2
if Pb-GasIn.Pt>1e-3
%     disp('孔单元发生逆流')
    [GasIn,Pb]=swap(GasIn,Pb);
    adverse=-1;
elseif abs(Pb-GasIn.Pt)<=1e-3
    GasOut.W=0;
    ed=[];
    return;  %不再向下执行Hole函数
else
    adverse=1;
end
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;
Swirl1=GasIn.Swirl;

gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;

D=data.D;
rf=data.rf;
L=data.L;
beta=data.beta;
theta0=data.theta0;
% RES=data.RES;
% Omega=RES*2*pi/60;

A=1/4*pi*data.D^2;
%% 判断流动状态
PI=Pt1/Pb; %落压比：进口总压与反压之比
PI_cr=((gamma+1)/2)^(gamma/(gamma-1));%临界压比，空气(k=1.4) Pt/Pcr=1.8929
P_cr=Pt1/PI_cr; %临界压力
if PI < PI_cr %亚临界流动状态
    data.choke=0; %未壅塞
%     disp('孔单元亚临界')
    Ps2=Pb;
    Ts2=Tt1/(Pt1/Ps2)^((gamma-1)/gamma);
    Ma2=TstarT2Ma(Tt1,Ts2);
elseif PI >= PI_cr %临界及超临界流动状态
    data.choke=1; %壅塞
%     fprintf('%s\n','孔出口壅塞')
    Ps2=P_cr;
    Ma2=1;
    Ts2=TstarMa2T(Tt1,Ma2);
end
Pt2=PMa2Pstar(Ps2,Ma2);
rhos2=Ps2/(R*Ts2);
c2=sqrt(gamma*R*Ts2);
V2=Ma2*c2;
W_id=rhos2*V2*A;%理想流量（等熵流动）
%% 入口截面流动特性：由质量守恒求进口截面马赫数及流动特性参数
[state]=WTcalcState(W_id,Pt1,Tt1,A,data.Cons); 
Ma1=state.Ma;
Ps1=state.Ps;
Ts1=state.Ts;
V1=state.V;
V_phi1=V1*sin(pi/2-beta);%切向速度
%V_phi1=Swirl1/data.r1;
Re1=W_id*D/(mu*A); % Re1=rhos1*V1*D/mu;
%% 实际流量：用流量系数修正理想流量
Cd=CdCalc(Re1,rf,D,L,Pt1,Ps2,V1,V_phi1,beta,theta0); %流量系数
W=Cd*W_id; %实际流量
[state2]=WScalcState(W,Ps2,Tt1,A,data.Cons); %出口截面流动参数
rhos2=state2.rhos;
V2=state2.V;
Ma2=state2.Ma;
Ts2=state2.Ts;
Pt2=state2.Pt;
%% 输出参数
ed.W=W;
ed.Ma2=Ma2;
ed.Swirl=GasIn.Swirl;
ed.Ts2=Ts2;
ed.Pt2=Pt2;
ed.Ps2=Ps2;%出口参数
ed.Ma1=Ma1;
ed.Ps1=Ps1;
ed.Ts1=Ts1;%入口参数

GasOut.W=adverse*ed.W*data.Num; %总流量
GasOut.Tt=GasIn.Tt; %Tt1=Tt2（绝能流动总温守恒）
GasOut.Ps=ed.Ps2;
GasOut.Pt=ed.Pt2;
GasOut.Ts=ed.Ts2;
GasOut.Swirl=ed.Swirl;%涡参数 Swirl=omega_air*r^2
end