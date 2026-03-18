function [Ps,Ts,Ma,rhos,V,Vg]=WcalcStat(Pt,Tt,W,A,data)
data.Pt=Pt;
data.Tt=Tt;
data.W=W;
data.A=A;%进口面积

R=data.Cons.R;
gamma=data.Cons.gamma;
cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;

opt.maxiter=500;
opt.tolfun=1e-8;
opt.tolx=1e-12;
icount=1;imax=1000;

while 1
    FUN=@(x) funwrapper(@WcalcStat_Body,x,data);%x为马赫数Ma， FUN=WcalcStat_Body（x,data）；
    bounds=[0 1];
    x0=rrd(0,1,1);%随意在(0,1)区间给定x0的初值。W/(Pt * divby(R * Tt)*A)/sqrt(1.4*R*Tt);
    try
        [Ma, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            Ma=round(Ma,7);
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('未收敛..., 需要Debug...(o_o)')
    end
end

%%
Ps=PstarMa2P(Pt,Ma);% 进口静参数
Ts=TstarMa2T(Tt,Ma);
Vg=sqrt(gamma*R*Ts);%当地声速
V=Vg*Ma;%绝对速度
rhos=Ps/(R*Ts);
end