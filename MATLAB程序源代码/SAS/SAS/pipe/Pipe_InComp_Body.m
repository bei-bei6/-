function [NErr,ed]=Pipe_InComp_Body(x,data)
R=data.Cons.R;
g=data.Cons.g;
gamma=data.Cons.gamma;
cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;

Tw=mean(data.Tw); %由于不可压模型只计算整体换热，因此在此取平均值
A=pi*(data.d/2)^2;
if data.flag==0 %data.flag=0;出口临界
    Ma2=1;
    Tt2=x;
    Ps2=data.Pb;
    Pt2=PMa2Pstar(Ps2,Ma2);
    Ts2=TstarMa2T(Tt2,Ma2);
elseif data.flag==1 % 出口超临界
    Ma2=1;
    Pt2=x(1);
    Tt2=x(2);
    Ps2=PstarMa2P(Pt2,Ma2);
    Ts2=TstarMa2T(Tt2,Ma2);
elseif data.flag==2 %出口亚临界
    Ma2=x(1);
    Tt2=x(2);
    Ps2=data.Pb;
    Pt2=PMa2Pstar(Ps2,Ma2);
    Ts2=TstarMa2T(Tt2,Ma2);
end

rhos2=Ps2/(R*Ts2);

Vg2=sqrt(gamma*R*Ts2); %出口截面音速
V2=Ma2*Vg2;
W=rhos2*V2*A;
%%
Re=rhos2*V2*data.d/mu;
if Re<=2000
    f=64/Re;
elseif Re>4000
    f=0.25/(log10(data.roughness/(3.7*data.d)+5.74/Re^0.9))^2;
else
    fl=64/2000;
    ft=0.25/(log10(data.roughness/(3.7*data.d)+5.74/4000^0.9))^2;
    x=(Re-2000)/2000;
    f=x*ft+(1-x)*fl;
end
%%
if data.type==1 
    % 外壁面散热，暂时忽略
    %{ 
    alpha_v=0.0036+10^-5*Ts2+10^-8*Ts2^2;
    Gr=abs(data.d^3*g*rhos2^2*alpha_v*(Ts2-Tw)/mu^2);
    Pr=cp*mu/k;
    if Gr*Pr>1e-5 && Gr*Pr<1e-3
        a=0.71;
        m=0.04;
    elseif Gr*Pr>1e-3 && Gr*Pr<1
        a=1.09;
        m=0.1;
    elseif Gr*Pr>1 && Gr*Pr<1e4
        a=1.09;
        m=0.2;
    elseif Gr*Pr>1e4 && Gr*Pr<1e9
        a=0.53;
        m=0.25;
    elseif Gr*Pr>1e9
        a=0.13;
        m=0.333;
    end
    Nu=a*(Gr*Pr)^m;
    h=Nu*k/data.d;
    q=h*(data.L*pi*data.d)*(Tw-Ts2);
    %}
    Pr=cp*mu/k;
    Nu=0.023*Re^0.8*Pr^0.4;% 管道湍流强制对流传热关联式
    h=Nu*k/data.d;
    q=h*(data.L*pi*data.d)*(Tw-Ts2);
else % data.type==0 管道绝热边界 'Adiabatic';
    q=0;
end
%%
Tt1=Tt2-q/cp/W;
Pt1=Pt2+f*data.L/data.d*W*abs(W)/(2*rhos2*A^2);
[Ps1,Ts1,Ma1,rhos1,V1,Vg1]=WcalcStat(Pt1,Tt1,W,A,data);
%%
ed.Pt1=Pt1;
ed.Ps1=Ps1;
ed.Tt1=Tt1;
ed.Pt2=Pt2;
ed.Ps2=Ps2;
ed.Tt2=Tt2;
ed.Ma=[Ma1 Ma2];
ed.W=W;
if data.flag==0
    NErr=(Tt1-data.GasIn.Tt)/data.GasIn.Tt;
elseif data.flag==1 || data.flag==2
    NErr(1)=(Pt1-data.GasIn.Pt)/data.GasIn.Pt;
    NErr(2)=(Tt1-data.GasIn.Tt)/data.GasIn.Tt;
end
end
