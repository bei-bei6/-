function [NErr,ed]=Bend_Circular_Body(x,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
mu=data.Cons.mu;

A=pi*(data.d/2)^2;
if data.flag==0
    Ma1=x;
    Ma2=1;
else
    Ma1=x(1);
    Ma2=x(2);
end
% X1=X(Ma1);
% X2=X(Ma2);
% K=X1-X2;
Ps1=PstarMa2P(data.GasIn.Pt,Ma1);
Ts1=TstarMa2T(data.GasIn.Tt,Ma1);
rhos1=Ps1/(R*Ts1);
Vg1=sqrt(gamma*R*Ts1);
V1=Vg1*Ma1;
W=rhos1*V1*A;

Re1=rhos1*V1*data.d/mu;

LossBasic=Bend_LossCoefCalc(data.r/data.d,data.theta);
Cf=MoodyChart(Re1,data.roughness,data.d)/MoodyChart(Re1,0,data.d);

if Re1>=1e4
    ReC=Bend_Re_Above10000Calc(Re1);
    K=LossBasic*ReC*Cf;
else
    ReC=Bend_Re_Above10000Calc(1e4);
    Ktur=Bend_Re_Below10000Calc(Re1)/Bend_Re_Below10000Calc(1e4);
    K=LossBasic*ReC*Cf*Ktur;
end

if data.flag==0
    data=wrapdata(data,A,W,K,Ma1,Ma2,rhos1);
    FUN=@(x) funwrapper(@Bend_Circular_rho,x,data);
    rhos2=secant(FUN,0,rhos1,1e-6,500);
    rhos=(rhos1+rhos2)/2;
    Pt2=data.GasIn.Pt-K*W^2/(2*rhos*A^2);
    Ps2=PstarMa2P(Pt2,Ma2);
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A;
    NErr=Wn-W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.Pt2=Pt2;
    ed.Ps1=Ps1;
    ed.PbCri=Ps2;
elseif data.flag==1
    Ps2=data.Pb;
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    rhos2=Ps2/(R*Ts2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A;
    rhos=(rhos1+rhos2)/2;
    Pt2=data.GasIn.Pt-K*W^2/(2*rhos*A^2);
    Ps2n=PstarMa2P(Pt2,Ma2);
    NErr(1)=(Ps2n-data.Pb)/data.Pb;
    NErr(2)=Wn-W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.Pt2=Pt2;
    ed.Ps1=Ps1;
    ed.Ps2=Ps2;
end
end