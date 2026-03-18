function [NErr,ed]=WcalcStat_Body(x,data)%流量计算公式；NErr =(Ma_new-Ma)/Ma；ed：Ts，Ps，Ma，rhos，V，Vg，W;
R=data.Cons.R;
cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;

Ma=x;%待求
Pt=data.Pt;
Tt=data.Tt;
W=data.W;
A=data.A;
Ps=PstarMa2P(Pt,Ma);
Ts = TstarMa2T(Tt,Ma);
rhos=Ps * divby(R * Ts);
V =W/(rhos*A);
Vg=sqrtT(1.4*R*Ts);%声速
Ma_new=V/Vg;
NErr =(Ma_new-Ma)/Ma;%【为什么这样取？】
%
ed.Ts=Ts;
ed.Ps=Ps;
ed.Ts=Ts;
ed.Ma=Ma;
ed.rhos=rhos;
ed.V=V;
ed.Vg=Vg;
ed.W=W;
end