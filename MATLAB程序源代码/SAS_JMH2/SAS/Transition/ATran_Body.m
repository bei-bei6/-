function [NErr,ed]=ATran_Body(x,data)%x为马赫数
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
%进口参数
Ps1=PstarMa2P(data.GasIn.Pt,Ma1);
Ts1=TstarMa2T(data.GasIn.Tt,Ma1);
rhos1=Ps1/(R*Ts1);
Vg1=sqrt(gamma*R*Ts1);%进口音速
V1=Vg1*Ma1;
W=rhos1*V1*A1;

Re1=rhos1*V1*data.d1/mu;
if data.d2>data.d1 %膨胀流
    CRe=ATran_CReCalc(Re1);%与进口雷诺数相关的损失系数：层流湍流损失系数
    AExp=ATran_AExpCalc(A1/A2);%与面积比A1/A2相关的损失系数：突然膨胀损失系数
    K=AExp*CRe;%局部损失因数
else
    CRe=ATran_CReCalc(Re1);
    ACon=ATran_ConCalc(A2/A1);%与面积比A2/A1相关的损失系数：突然收缩损失系数
    K=ACon*CRe;%局部损失因数
end
if data.flag==0 %壅塞
    data=wrapdata(data,A1,A2,W,K,Ma1,Ma2,rhos1);%将A1,A2,W,K,Ma1,Ma2,rhos1放入data结构数组中变成data.A1,...
    FUN=@(x) funwrapper(@ATran_rho,x,data);%x为出口密度rhos2
    rhos2=secant(FUN,0,rhos1,1e-6,500);
    rhos=(rhos1+rhos2)/2;
    Pt2=data.GasIn.Pt-K*W^2/(2*rhos*A1^2);
    Ps2=PstarMa2P(Pt2,Ma2);
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A2;
    NErr=Wn-W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.PtbCri=Ps2;
    ed.Ps1=Ps1;
    ed.Pt2=Pt2;
elseif data.flag==1 %未壅塞
    Ps2=data.Pb;%已知
    Pt2=PMa2Pstar(Ps2,Ma2);
    Ts2=TstarMa2T(data.GasIn.Tt,Ma2);
    rhos2=Ps2/(R*Ts2);
    Vg2=sqrt(gamma*R*Ts2);
    V2=Vg2*Ma2;
    Wn=rhos2*V2*A2;
    rhos=(rhos1+rhos2)/2;
    Pt2n=data.GasIn.Pt-K*W^2/(2*rhos*A1^2);
    NErr(1)=(Pt2n-Pt2)/Pt2;
    NErr(2)=Wn-W;
    ed.W=W;
    ed.Ma1=Ma1;
    ed.Ma2=Ma2;
    ed.Pt2=Pt2;
    ed.Ps2=Ps2;
    ed.Ps1=Ps1;
end
end