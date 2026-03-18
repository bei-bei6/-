function [NErr,ed]=Duct_Body(x,data)
Ma1=x; % 要求的流量
CaseOpt=data.CaseOpt;

gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

Pt1=data.GasIn.Pt;
Tt1=data.GasIn.Tt;
Ps2=data.Ps2;%true value
A=data.A;
A1=data.A1;
A2=data.A2;
Aw=data.Aw;
D=data.D;

Fft1=Ma1*sqrt(gamma/(1+(gamma-1)/2*Ma1^2)^((gamma+1)/(gamma-1)));%无量纲总压质量流量函数
W=A1*Fft1*Pt1/sqrt(R*Tt1);

[state1]=WTcalcState(W,Pt1,Tt1,A1,data.Cons); %入口截面流动参数
rhos1=state1.rhos;
V1=state1.V;
Ps1=state1.Ps;
Ts1=state1.Ts;
%% 能量守恒方程
switch CaseOpt.htt % 传热类型
    case 0 % 给定热流
        deltaT_ht = data.q*Aw/(W*cp);
    case 1
        Re=W*D/(mu*A);
        if data.Tw>Tt1
            Nu=0.023*Re^0.8*Pr^0.4;
        else
            Nu=0.023*Re^0.8*Pr^0.3;
        end
        h=k/D*Nu;
        NTU=h*Aw/(W*cp);
        deltaT_ht = (data.Tw-Tt1)*(1-exp(-NTU)); % Heat Transfer
end
deltaT_cct = 0;
switch CaseOpt.rot %是否旋转
    case 0 % 静止
        deltaT_rot = 0;
    case 1 % 旋转
        deltaT_rot = (data.RES*2*pi/60)^2*(data.r2^2-data.r1^2)/(2*cp);% Rotational work transfer
        if CaseOpt.htt==1
        deltaT_cct = (data.RES*2*pi/60)^2*(data.r2-data.r1)*data.r1*NTU/(2*cp); % Coupling Correction Term
        end
end
Tt2 = Tt1 + deltaT_ht + deltaT_rot + deltaT_cct;
%% 出口截面马赫数及流动参数
[state2]=WScalcState(W,data.Ps2,Tt2,A2,data.Cons); %出口截面流动参数
rhos2=state2.rhos;
V2=state2.V;
Ma2=state2.Ma;
Ts2=state2.Ts;
Pt2=state2.Pt;
%% 动量方程
ave_rhos=(rhos1+rhos2)/2;
ave_V=(V1+V2)/2;
ave_A=data.A;
Re=W*data.D/(mu*A);
if Re<=2000
    f=64/Re;
elseif Re>4000
    f=0.25/(log10(data.roughness/(3.7*data.D)+5.74/Re^0.9))^2;
else
    fl=64/2000;
    ft=0.25/(log10(data.roughness/(3.7*data.D)+5.74/4000^0.9))^2;
    p=(Re-2000)/2000;
    f=p*ft+(1-p)*fl;
end % 达西摩擦因子
if data.CaseOpt.A == 1
    L=sqrt(data.L^2+(data.D2/2-data.D1/2)^2);%管道侧表面积
else
    L=data.L;%管道侧表面积
end
deltaP_f = f*L/data.D*0.5*ave_rhos*ave_V^2; % 摩擦引起的静压变化
deltaP_rot = 0;  % 旋转引起的静压变化
if CaseOpt.rot==1
    deltaP_rot = ave_rhos*(data.RES*2*pi/60)^2*(data.r2^2-data.r1^2)/2;
end
deltaP_mom = W*(V2-V1)/ave_A; % 动量变化引起的静压变化
Ps2 = Ps1 - deltaP_f + deltaP_rot - deltaP_mom; % Ps2'

NErr=(Ps2-data.Ps2)/data.Ps2;

ed.Pt1=Pt1;
ed.Ps1=Ps1;
ed.Tt1=Tt1;
ed.Ts1=Ts1;
ed.V1=V1;
ed.Pt2=Pt2;
ed.Ps2=Ps2;
ed.Tt2=Tt2;
ed.Ts2=Ts2;
ed.Ma=[Ma1 Ma2];

flowdirection=cp/R*log(Ts2/Ts1)-log(Ps2/Ps1);
%flowdirection=cp/R*log(Tt2/Tt1)-log(Pt2/Pt1);

end