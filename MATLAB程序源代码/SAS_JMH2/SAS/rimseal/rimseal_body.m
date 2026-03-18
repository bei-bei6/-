function [residual,ed]=rimseal_body(x,data)
%%
load Flow_Coefficient_Surface.mat Flow_Coefficient_Surface
load Virtual_Seal_Factor.mat Virtual_Seal_Factor
load loss_coe.mat loss_coe
%%
Pt1=data.GasIn.Pt;
Tt1=data.GasIn.Tt;
Swril1=data.GasIn.Swirl;

N=data.N;
Sc_ax=data.Sc_ax; %间隙Cr
B=data.B;
Sc_rad=data.Sc_rad; %齿间距Lr
S_buffer=data.S_buffer;
b=data.b; %rb
sign=data.sign;
g=data.Cons.g;
R=data.Cons.R;
gamma=data.Cons.gamma;
mu=data.Cons.mu;

A=2*pi*b*Sc_ax; %环形封严间隙面积


%%
if sign==0 %亚临界状态
    Pb=data.Pb;
    Ps2=Pb;
    Ma2=x; %出口马赫数
    Tt2=Tt1;
    Ts2=TstarMa2T(Tt2,Ma2);
    Pt2=PMa2Pstar(Pb,Ma2);
    rho2=Pb/(R*Ts2);
    Vs2=sqrt(gamma*R*Ts2);
    V2=Ma2*Vs2;
    y_c=interp1(Virtual_Seal_Factor(:,1),Virtual_Seal_Factor(:,2),Sc_rad/Sc_ax);%虚密封系数y'，齿间距Sc_rad和封严间隙Sc_ax
    N_c=N/2*y_c; %虚齿数n'
    D=A/(pi*Sc_ax); % 水力直径=2b
    Re2=rho2*V2*D/mu;
    C_K=interp2K(Flow_Coefficient_Surface,B/Sc_ax,Re2);%流量系数
    alpha=8.52/((S_buffer-B)/Sc_ax+7.23); %
    F=1/sqrt(1-alpha); %动能承转系数
    W=C_K*F*A*alpha*Pt1/sqrt(R*Tt1)*sqrt((1-(Pb/Pt1)^2)/(N_c-log(Pb/Pt1)));
    %
    zeta=interp1(loss_coe(:,1),loss_coe(:,2),Sc_rad/Sc_ax);
    deltaP=zeta*V2^2/(2*g)*rho2;
    Pt2_new=Pt1+deltaP;
    %
    residual=Pt2_new-Pt2;
elseif sign==1 %临界状态（壅塞）
    Pt2=x; %出口总压
    Tt2=Tt1;
    Ps2=PstarMa2P(Pt2,1);
    Ts2=TstarMa2T(Tt2,1);
    rho2=Ps2/(gamma*Ts2);
    Vs2=sqrt(gamma*R*Ts2);
    y_c=interp1(Virtual_Seal_Factor(:,1),Virtual_Seal_Factor(:,2),Sc_rad/Sc_ax);%虚密封系数y'
    N_c=N/2*y_c; %虚齿数n'
    D=A/(pi*Sc_ax); % 水力直径
    Re2=rho2*Vs2*D/mu;
    C_K=interp2K(Flow_Coefficient_Surface,B/Sc_ax,Re2); %流量系数
    alpha=8.52/((S_buffer-B)/Sc_ax+7.23);
    F=1/sqrt(1-alpha);%动能承转系数
    W=C_K*F*A*alpha*Pt1/sqrt(R*Tt1)*sqrt((1-(Ps2/Pt1)^2)/(N_c-log(Ps2/Pt1)));
    %
    zeta=interp1(loss_coe(:,1),loss_coe(:,2),Sc_rad/Sc_ax);
    deltaP=zeta*Vs2^2/(2*g)*rho2;
    Pt2_new=Pt1+deltaP;
    %
    residual=Pt2_new-Pt2;
end
ed.W=W;
ed.Pt2=Pt2;
ed.Ps2=Ps2;
ed.Tt2=Tt2;
ed.Swirl2=Swril1; %计算出口：流量、总压（静压）、总温、Swirl
end