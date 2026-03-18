function [dydt,ed]=Pipe_Body(t,y,data)
%修改该程序以用于GUI界面计算
Ts_ave=y(1);%管路内温度
Ps_ave=y(2);%管路内压力
%%
Rt=data.Cons.Rt;
gamma=data.Cons.C_GAMMA;
% g=data.Cons.g;
%%
Pt1=data.GasIn.Pt;%入口总压
Tt1=data.GasIn.Tt;%入口总温
Psout=data.Psout;%出口背压
%% 体积
valve_opening=data.HPTvalve+(data.valve_opening-data.HPTvalve)*exp(-t*divby(data.HPTDeflate.Delay));

Ain=data.Ain; %inlet和outlet面积
Aout=data.Aout; %inlet和outlet面积
Cd_in=data.Cd_in;
Cd_out=data.Cd_out;
Vcv=data.Volume;%体积
%% 物性
% cp=CoolProp.PropsSI('C','P',Ps_ave,'T',Ts_ave,'Air');
% 
% cv=CoolProp.PropsSI('CVMASS','P',Ps_ave,'T',Ts_ave,'Air');
cp=1004;
cv=1004-287;
cpin=cp;
cpout=cp;
%% 稳定性
if Ps_ave>=Pt1
    Ps_ave=Pt1;
elseif  Ps_ave<=Psout
    Ps_ave=Psout;
end
%% 进出口流量方程
if Ps_ave/Pt1>0.528%没有滞止
    Win=valve_opening*Cd_in*Ain*Pt1/sqrt(Rt*Tt1)*sqrt(2*gamma/(gamma-1)*(Ps_ave/Pt1)^(2/gamma)*(1-(Ps_ave/Pt1)^((gamma-1)/gamma)));
else
    Win=Cd_in*Ain*Pt1/sqrt(Rt*Tt1)*sqrt(2*gamma/(gamma-1)*(0.528)^(2/gamma)*(1-(0.528)^((gamma-1)/gamma)));   %需要改 
end

if Psout/Ps_ave>0.528  
    Wout=Cd_out*Aout*Ps_ave/sqrt(Rt*Ts_ave)*sqrt(2*gamma/(gamma-1)*(Psout/Ps_ave)^(2/gamma)*(1-(Psout/Ps_ave)^((gamma-1)/gamma)));
else
    Wout=Cd_out*Aout*Ps_ave/sqrt(Rt*Ts_ave)*sqrt(2*gamma/(gamma-1)*(0.528)^(2/gamma)*(1-(0.528)^((gamma-1)/gamma)));
end

% if ~isreal(Win) || ~isreal(Wout)
%     fprintf('%s\n','Pipe出现虚数')
%     return
% end

 Qnet=0;

%% 控制方程
Wcv=Ps_ave*Vcv/(Rt*Ts_ave);
dydt=zeros(2,1);
dcvdTs_ave=0;
% dcvdTs_ave=jacobianest(@(x) cv_T(x,Ps_ave),Ts_ave);
Ttout=Ts_ave;
dydt(1)=1/(Wcv*(Ts_ave*dcvdTs_ave+cv))*(Win*cpin*Tt1-...
    Wout*cpout*Ttout-cv*Ts_ave*(Win-Wout)+Qnet);
dydt(2)=Rt*Ts_ave/Vcv*(Win-Wout)+Ps_ave/Ts_ave*dydt(1);
%%
ed.t=t;
ed.Ts_ave=Ts_ave;
ed.Ps_ave=Ps_ave;
ed.Win=Win;
ed.Wout=Wout;
ed.W=(Win+Wout)/2;
ed.Qnet=Qnet;
ed.Pt=Ps_ave;%管路内压力
ed.Tt=Ts_ave;%管路内温度
ed.ValveOpening=valve_opening;
end