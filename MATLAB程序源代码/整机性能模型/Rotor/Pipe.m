function [GasOut,ed]=Pipe(GasIn,data)
%
if data.Psout>GasIn.Pt
    fprintf('%s\n','盘腔存在逆流')
    [GasIn,data.Psout]=swap(GasIn,data.Psout);
    adverse=-1;
else
    adverse=1;
end
%
y0=[GasIn.Tt,data.Psout*1];%管路内的初始温度和压力
% data.GasIn=GasIn;
tspan=0:data.deltat/100:data.deltat;%时间步长
F=@(t,y) funwrapper2(@Pipe_Body,t,y,data);%t为时间，y为[温度,压力]

[t,y] = ode23s(F,tspan,y0);

y=real(y); 
[~,ed]=Pipe_Body(t(end),y(end,:),data);



GasOut.W=adverse*ed.W;%
GasOut.Tt=ed.Tt;%出口气流总温
GasOut.Pt=ed.Pt;%
GasOut.Ts=y(end,1);
GasOut.Ps=y(end,2);
%获得变化过程
ed.t=t;
ed.y=y;
for i=1:length(ed.t)
    [~,uu]=Pipe_Body(t(i),y(i,:),data);
    ed.uu(i)=uu.Win;
end
end