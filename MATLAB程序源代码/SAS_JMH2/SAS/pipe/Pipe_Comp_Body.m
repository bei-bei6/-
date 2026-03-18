function [NErr,ed]=Pipe_Comp_Body(x,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
if data.flag==0 % 出口临界
    Ma2=0.999;
    Ps2=data.Pb;
    Ts2=TstarMa2T(x,Ma2); 
elseif data.flag==1 % 出口超临界
    Ma2=0.999;
    Ps2=PstarMa2P(x(1),Ma2);
    Ts2=TstarMa2T(x(2),Ma2); 
elseif data.flag==2  % 出口亚临界
    Ma2=x(1);
    Ps2=data.Pb;
    Ts2=TstarMa2T(x(2),Ma2); 
end

A=pi*(data.d/2)^2;

Vg2=sqrt(gamma*R*Ts2);
V2=Ma2*Vg2;
rhos2=Ps2/(R*Ts2);
W=rhos2*V2*A;
y1_0 = Ps2; y2_0 = V2; y3_0 = Ts2;
xspan=linspace(data.L,0,data.N);
options = odeset('Events',@(t,y)Pipe_eventfun(t,y,data));
F=@(x,y) funwrapper2(@Pipe_Comp_Body_Body,x,y,data);
[t,y] = ode45(F,xspan,[y1_0 y2_0 y3_0],options);

Ma2=y(:,2)./sqrt(gamma.*R.*y(:,3));
Pt2=y(:,1).*(1+(gamma-1)/2.*Ma2.^2).^(gamma/(gamma-1));
Tt2=y(:,3).*(1+(gamma-1)/2.*Ma2.^2);
if data.flag==0
    NErr=(Tt2(end)-data.GasIn.Tt)/data.GasIn.Tt;
elseif data.flag==1 || data.flag==2
    NErr(1)=(Pt2(end)-data.GasIn.Pt)/data.GasIn.Pt;
    NErr(2)=(Tt2(end)-data.GasIn.Tt)/data.GasIn.Tt;
end
ed.Ma=Ma2;
ed.Pt=Pt2;
ed.Ps=y(:,1);
ed.Tt=Tt2;
ed.Ts=y(:,3);
ed.W=W;
end