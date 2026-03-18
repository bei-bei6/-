function [NErr,ed]=GTran_Body(x,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
mu=data.Cons.mu;

if data.flag==0
    if data.d1<data.d2 
        Ma1=1;
        Ma2=x;
    else
        Ma1=x;
        Ma2=1;
    end
else
    Ma1=x(1);
    Ma2=x(2);
end
A1=pi*(data.d1/2)^2;
A2=pi*(data.d2/2)^2;

Ps1=PstarMa2P(data.GasIn.Pt,Ma1);
Ts1=TstarMa2T(data.GasIn.Tt,Ma1);
rhos1=Ps1/(R*Ts1);
Vg1=sqrt(gamma*R*Ts1);
V1=Vg1*Ma1;
W=rhos1*V1*A1;

Re1=rhos1*V1*data.d1/mu;
if data.d2>data.d1 %≈Ú’Õ¡˜
    CRe=GTran_CReCalc(Re1);
    Kd=GTran_KdDCalc(data.L/(data.d1/2),A2/A1);
    K=Kd*CRe;
else
    Kr=0.06;
    K=Kr;
end
if data.flag==0
    data=wrapdata(data,A1,A2,W,K,Ma1,Ma2,rhos1);
    FUN=@(x) funwrapper(@GTran_rho,x,data);
    rhos2=secant(FUN,0,rhos1,1e-6,500);
    rhos=(rhos1+rhos2)/2;
    Pt2=data.GasIn.Pt-K*W^2/(2*rhos*A1^2);
    Ps2=PstarMa2P(Pt2,Ma2);
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A2;
    NErr=(Wn-W)/W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.Ps1=Ps1;
    ed.PtbCri=Ps2;
    ed.Pt2=Pt2;
elseif data.flag==1
    Ps2=data.Pb;
    Pt2=PMa2Pstar(Ps2,Ma2);
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    rhos2=Ps2/(R*Ts2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A2;
    rhos=(rhos1+rhos2)/2;
    Pt2n=data.GasIn.Pt-K*W^2/(2*rhos*A1^2);
    NErr(1)=(Pt2n-Pt2)/Pt2;
    NErr(2)=(Wn-W)/W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.Pt2=Pt2;
    ed.Ps2=Ps2;
    ed.Ps1=Ps1;
end
end