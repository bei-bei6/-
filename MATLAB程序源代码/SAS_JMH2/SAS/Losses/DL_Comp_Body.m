function [NErr,ed]=DL_Comp_Body(x,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
Radius=data.D/2;
A=pi*Radius^2;

Ma1=x(1);Ma2=x(2);
Ps1=PMa2Pstar(data.GasIn.Pt,Ma1);
Ps2=data.Psout;
Pt2=PMa2Pstar(Ps2,Ma2);
NErr(1)=X(Ma1)-X(Ma2)-data.flc*double(data.adverse==1)-data.rlc*double(data.adverse==-1);
W1=(gamma^0.5*Ma1/(1+(gamma-1)*Ma1^2/2)^((gamma+1)/(2*(gamma-1)))*A)*data.GasIn.Pt/(R*data.GasIn.Tt)^0.5;
W2=(gamma^0.5*Ma2/(1+(gamma-1)*Ma2^2/2)^((gamma+1)/(2*(gamma-1)))*A)*Pt2/(R*data.GasIn.Tt)^0.5;
NErr(2)=(W1-W2);
ed.W=(W1+W2)/2;
ed.Ps1=Ps1;
ed.Ps2=Ps2;
ed.Pt2=Pt2;
end
