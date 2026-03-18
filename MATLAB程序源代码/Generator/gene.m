clear,clc
close all
%
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\Generator'));
% Parameters of a 500 MVA, 30 kV Synchronous Machine
data.Generator.f=50;
data.Generator.Ld=0.0072;
data.Generator.Lq = 0.0070;
data.Generator.L0=0.0010;
data.Generator.LF = 2.500;
data.Generator.LD = 0.0068;
data.Generator.LQ = 0.0016;
data.Generator.MF = 0.100; 
data.Generator.MD = 0.0054; 
data.Generator.MQ = 0.0026; 
data.Generator.MR = 0.1250;
data.Generator.rF = 0.4000;
data.Generator.rD = 0.015; 
data.Generator.rQ = 0.0150;

data.Generator.R = 150; %外阻
data.Generator.r = 0.002*1000; %内阻
data.Generator.w=2.*pi*data.Generator.f;

MF=data.Generator.MF;
Ld=data.Generator.Ld;
Lq=data.Generator.Lq;
r=data.Generator.r+data.Generator.R;
f=data.Generator.f;
w=data.Generator.w;
R=data.Generator.R;
rF =data.Generator.rF;%励磁绕组电阻

data.Generator.Udemand=20000;
fenzi=(w*Ld*w*Lq/(r)+r)*rF;
fenmu=w*MF*R*sqrt(1+(w*Lq/r)^2);
data.Generator.VF = 1.414213562373095*data.Generator.Udemand*fenzi/fenmu; %励磁电压

VF =data.Generator.VF;%励磁电压
iF0 =VF/rF;%励磁绕组初始电流

pi2=2.*pi/3;
% d = 0; d = d*pi/180;

t0 = 0 ; tfinal = 50;
i_start = [0; 0; 0; iF0; 0; 0;]; % Initial currents电压初值

Generator=@(tspan,i0) funwrapper2(@Gllshort,tspan,i0,data.Generator);%

% tspan = t0:0.0005:tfinal; % 步长0.0005为1/40的周期
%
data.Gene_deltat=0.1;
data.Generator.Kp=0.1;%0.05
data.Generator.Ki=0.1;

data.Gene_PI_in=VF;
data.Gene_int_error=0;
t0=0;tend=data.Gene_deltat;
time=[];ueff=[];Pge=[];Iall=[];Ufall=[];Ia_all=[];
while 1
    data.Generator.R=interp1g([-1;20;20;100],[150;150;1000;1000],t0);
    tspan=t0:0.0005:tend; 
    t0=tend;
    tend=t0+data.Gene_deltat;
    Generator=@(tspan,i0) funwrapper2(@Gllshort,tspan,i0,data.Generator);%
    [t,i] = ode23s(Generator, tspan, i_start); % use for MATLAB 5
    id=-i(:,1); iq=-i(:,2);i0=-i(:,3);iF=i(:,4); iD=i(:,5); iQ=i(:,6);
    i_start=[-id(end);-iq(end);-i0(end);iF(end);iD(end);iQ(end)];
    %current dq0 to current abc
    nn=length(id);
    for kk=1:nn
        tt=t(kk);thetaa=w*tt;thetab=thetaa-pi2;thetac=thetaa+pi2;
        ia(kk)=cos(thetaa)*id(kk)-sin(thetaa)*iq(kk)+i0(kk);
%         ib(kk)=cos(thetab)*id(kk)-sin(thetab)*iq(kk)+i0(kk);
%         ic(kk)=cos(thetac)*id(kk)-sin(thetac)*iq(kk)+i0(kk);
    end
Ufall=[Ufall,data.Generator.VF];
Ia_all=[Ia_all,ia];
    [time_i,ueff_i]=CalcuRMS(t,ia*data.Generator.R,length(tspan)); 
    [data.Generator.VF,data.Gene_int_error]=GenePID(data.Generator.Udemand,ueff_i,data);
    ieff_i=ueff_i./data.Generator.R;
    time=[time,time_i];
    ueff=[ueff,ueff_i];
    Pge=[Pge,3*ieff_i*ueff_i+3*ieff_i*ieff_i*data.Generator.r];
    Iall=[Iall,ieff_i];
    
    if tend>tfinal
        break;
    end
    
%     if t0>5
%         data.Generator.R=1500;
%     end
        
end
figure
plot(time,ueff)
xlabel('时间/s')
ylabel('输出端电压有效值/V')
figure
plot(time,Pge)
xlabel('时间/s')
ylabel('功率/W')
figure
plot(time,Iall)
xlabel('时间/s')
ylabel('电流有效值/A')

figure
plot(time,Ufall)
xlabel('时间/s')
ylabel('励磁电压/V')

figure
plot(0:0.0005:0.0005*(length(Ia_all)-1),Ia_all)
xlabel('时间/s')
ylabel('电流瞬时值/A')