function [NErr,ed]=PreswirlNozzle_Body(x,data)
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;

Pt1=data.GasIn.Pt;
Tt1=data.GasIn.Tt;
D=data.D;
rf=data.rf;
L=data.L;
RR=data.RR;%【RR?旋转半径？】
beta=data.beta;%预旋喷嘴倾角
%%
A=1/4*pi*D^2;
%
Ma1=x(1);%未知数x(1)：入口马赫数；迭代初值=rand
Psout=x(2);%未知数x(2)：实际出口压力；迭代初值=Pcr
%
Ps1=PstarMa2P(Pt1,Ma1);
Ts1=TstarMa2T(Tt1,Ma1);
Vg1=sqrt(gamma*R*Ts1);
Vx1=Ma1*Vg1;
V_phi1=Vx1*sin(pi/2-beta);
rhos1=Ps1/(R*Ts1);
Re1=rhos1*Vx1*D/mu;%入口截面各参数均为入口马赫数x(1)的函数
rhot1=Pt1/(R*Tt1);%总密度（已知）

if data.choke==1 %壅塞时，出口马赫数Ma2=1，出口静压Psout为临界压力Pcr=Ptin*[2/(k+1)]^[k/(k-1)]；
    % Psout=GasIn.Pt/((gamma+1)/2)^(gamma/(gamma-1))
    Cd=CdCalc(Re1,rf,D,L,Pt1,Psout,Vx1,V_phi1,beta);%修正后的流量系数Cd为入口马赫数x(1)、实际出口压力x(2)的函数。
    W=Cd*A*rhot1*(Psout/Pt1)^(1/gamma)*(2*gamma/(gamma-1)*Pt1/rhot1*(1-(Psout/Pt1)^((gamma-1)/gamma)))^0.5;%实际流量为入口马赫数x(1)、实际出口压力x(2)的函数。
else
    Psout=data.Psout;
    Cd=CdCalc(Re1,rf,D,L,Pt1,Psout,Vx1,V_phi1,beta);
    W=Cd*A*rhot1*(Psout/Pt1)^(1/gamma)*(2*gamma/(gamma-1)*Pt1/rhot1*(1-(Psout/Pt1)^((gamma-1)/gamma)))^0.5;
end
W1=rhos1*Vx1*A;

if beta==0
    Swirl=data.GasIn.Swirl;
else
    Swirl=Vx1*sin(pi/2-beta)*RR; 
end

if data.choke==1%壅塞时，所有参数都能直接算出
    Ma2=1;
    Ts2=TstarMa2T(Tt1,Ma2);
    rhos2=Psout/(R*Ts2);
    Vg2=sqrt(gamma*R*Ts2);
    Vx2=Ma2*Vg2;
    W2=rhos2*Vx2*A;
    NErr=[W-W1;W-W2];
else %出口马赫数Ma2未知
    Psout=data.Psout;
    fun=@(Ma2) W-A*sqrt(gamma/R)*Ma2*Psout/sqrt(Tt1/(1+(gamma-1)/2*Ma2^2));%W-W2；massflow(Tt1,Psout,Ma2,A);
    options = optimoptions('fsolve','Display','off');
    Ma2 = fsolve(fun,0.5,options);% 求解Ma2
    NErr=[W-W1;Psout-x(2)];
end
Pt2=PMa2Pstar(data.Psout,Ma2);%【“注意，原始为Pt2=PMa2Pstar(Psout,Ma2)”】
Ts2=TstarMa2T(Tt1,Ma2);
%%
ed.W=W;
ed.Ma2=Ma2;
ed.Swirl=Swirl;
ed.Ts2=Ts2;
ed.Pt2=Pt2;
ed.Ps2=Psout;
end