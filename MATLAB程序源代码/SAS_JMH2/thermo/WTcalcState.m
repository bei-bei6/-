function [state]=WTcalcState(W,Pt,Tt,A,Cons)
%给定截面流量和总温总压，计算该截面流动静参数
R=Cons.R;
gamma=Cons.gamma;

F_ft=W.*sqrt(R*Tt)./(A.*Pt); % Dimensionless total-pressure mass flow function
fun=@(Ma) F_ft-Ma.*sqrt(gamma/(1+(gamma-1)/2.*Ma^2)^((gamma+1)/(gamma-1)));
options=optimoptions('fsolve','Display','off');
Ma=fsolve(fun,0.5,options);

Ps=PstarMa2P(Pt,Ma);
Ts=TstarMa2T(Tt,Ma);
rhos=Ps./(R*Ts);
c=sqrt(gamma*R.*Ts); %当地声速
V=c.*Ma; %绝对速度

%截面静参数
state.Ma=Ma;
state.Ps=Ps;
state.Pt=Pt;
state.Ts=Ts;
state.rhos=rhos;
state.c=c;
state.V=V;
end