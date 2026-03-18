function [GasOut,ed]=Labyrinth(GasIn,Pb,data)
%%  Neumann公式
R=data.Cons.R;
gamma=data.Cons.gamma;
data.GasIn=GasIn;
data.Pb=Pb;
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;
n=data.NT; % 齿数
data.A=2*pi*data.Ri*data.Cri; %间隙通流面积

if data.Pb>data.GasIn.Pt
    fprintf('%s\n','篦齿逆流')
    data.adverse=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
end
PI=Pt1/Pb; %落压比：进口总压与反压之比
PI_cr=1.4115+0.5261*n-0.0363*n^2+0.0014*n^3;%临界压比，空气(k=1.4) Pt/Pcr=1.8929
if PI < PI_cr %亚临界流动状态
    data.choke=0; %未壅塞
    disp('篦齿单元亚临界')
else PI >= PI_cr %最后一个齿壅塞
    data.choke=1; %壅塞
    fprintf('%s\n','篦齿单元最后一齿处壅塞')
end
% k=sqrt(n/(n-1))*sqrt(1/(1-((n-1)/n*((data.Cri/data.Li)/(data.Cri/data.Li+0.02)))));
% Cd=pi/(pi+2);
% a=1-1/(1+16.6*data.Cri/data.Li)^2;
% mu=sqrt(n/(n*(1-a)+a));
% W=k*Cd*data.A*Pt1/sqrt(R*Tt1);
%%
Pt(data.NT)=data.Pb;
Pt(data.NT-1)=Pt(data.NT)*((gamma+1)/2)^(gamma/(gamma-1)); %式3.41 假设篦齿堵塞，由临界流动条件得到P_n-1
b=1-((gamma+1)/2)^(-2*gamma/(gamma-1)); %式3.27
for i=data.NT:-1:1
    if i~=1
        mu=1+0.0791*(data.NT-1); %式3.12
    elseif i==1
        mu=1;
    end
    if i==data.NT
        S(i)=(Pt(i-1)/Pt(i))^((gamma-1)/gamma)-1;
        W=Pt(data.NT-1)*pi*sqrt(b)/(pi+5+0.5*gamma^2-3.5*gamma)*mu*data.A/sqrt(R*data.GasIn.Tt); %式3.44
    else
        S(i)=secant(@(x) W-pi*Pt(i)/(pi+2-5*x+2*x^2)*sqrt((x+1)^(2*gamma/(gamma-1))-1)*mu*data.A/sqrt(R*data.GasIn.Tt),0,10,1e-6,500);
        S(i)=real(S(i));
        if i~=1
            Pt(i-1)=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
        else
            Pt0=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
        end
    end
end
%
if Pt0<=data.GasIn.Pt
    data.choked=1; %篦齿堵塞
    fprintf('%s\n','篦齿堵塞')
else
    data.choked=0; %篦齿未堵塞
    fprintf('%s\n','篦齿未堵塞')
end
FUN=@(x) funwrapper(@LSST_Implicit_Body,x,data);
PNT_1 = secant(FUN,data.Pb,data.GasIn.Pt,1e-6,500);
[~,ed_impicit]=LSST_Implicit_Body(PNT_1,data);
GasOut.W=ed_impicit.W;
GasOut.Pt=ed_impicit.Pt(end);
% GasOut.Tt=GasIn.Tt;
[V,taur,taus]=LSST_Circumferential_Vec(ed_impicit.W,ed_impicit.S,data);%用周向动量方程计算齿腔内周向速度分布
GasOut.Swirl=V(end)*data.Ri;
ed=ed_impicit;
ed.V=V;

%%
GasOut.Ps=data.Pb;

GasOut.Tt=GasIn.Tt;
end