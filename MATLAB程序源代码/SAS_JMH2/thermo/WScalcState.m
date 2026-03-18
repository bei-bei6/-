function [state]=WScalcState(W,Ps,Tt,A,Cons)
%给定截面流量和总温、静压，计算该截面马赫数及流动参数
R=Cons.R;
gamma=Cons.gamma;

F_fs=W*sqrt(R*Tt)/(A*Ps); % Dimensionless static-pressure mass flow function

fun=@(Ma) F_fs-Ma*sqrt(gamma*(1+(gamma-1)/2*Ma^2));
options=optimoptions('fsolve','Display','off');
Ma=fsolve(fun,0.5,options);

Pt=PMa2Pstar(Ps,Ma);
Ts=TstarMa2T(Tt,Ma);
rhos=Ps/(R*Ts);
c=sqrt(gamma*R*Ts); %当地声速
V=c*Ma; %绝对速度

%截面流动参数
state.Ma=Ma;
state.Ps=Ps;
state.Pt=Pt;
state.Ts=Ts;
state.rhos=rhos;
state.c=c;
state.V=V;
end