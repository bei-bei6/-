clear,clc
close all
%
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\Generator'));
%% input
%nominal
S_rated=1.588e+06;%额定视在功率，VA
U_rated=10000;%额定电压=单相电压的有效值,V
BASE_f=50;%基值频率,Hz
%stator
Generator.Rs=0.0016;%定子内阻
Generator.Llou=1.414e-05;
Generator.Lmd=0.001075;
Generator.Lmq=0.0007917;
%field（注意field基值不一样）
Generator.Rf=0.0004763;%励磁内阻
Generator.Lloufd=0.0004701;
%damper
Generator.Rkd=0.1821;%阻尼D绕组内阻
Generator.Lloukd=0.006717;
Generator.Rkq=0.002909;%阻尼Q绕组内阻
Generator.Lloukq=7.338e-05;
%外接参数
Generator.w=2*pi*BASE_f;
Generator.R=30; %单相外阻/omu
%目标电压
Generator.Udemand=U_rated;%单相电压的有效值,V
%%
X0=1;
Lmd=Generator.Lmd;
Lmq=Generator.Lmq;
Lflou=Generator.Lloufd;
LDlou=Generator.Lloukd;
LQlou=Generator.Lloukq;
Llou=Generator.Llou;

Xad=Lmd;
Xaq=Lmq;
Xd=Lmd+Llou;
Xq=Lmq+Llou;
Xf=Lmd+Lflou;
XD=Lmd+LDlou;
XQ=Lmq+LQlou;    
L=[Xd 0 0 Xad Xad 0
0 Xq 0 0 0 Xaq
0 0 X0 0 0 0
Xad 0 0 Xf Xad 0
Xad 0 0 Xad XD 0
0 Xaq 0 0 0 XQ];
%%
%励磁系统初始电压
fenzi=(Generator.Lmd+Generator.Llou+((Generator.R+Generator.Rf)/Generator.w)^2/(Generator.Lmq+Generator.Llou))*Generator.Rf;
fenmu=Generator.Lmd*Generator.R*sqrt(1+((Generator.R+Generator.Rf)/(Generator.Lmq+Generator.Llou)/Generator.w)^2);
Generator.VF=sqrt(2)*Generator.Udemand*fenzi/fenmu;%当输出电压为目标电压时对应的励磁系统电压标幺值
%%
Generator.VF=Generator.VF; %励磁电压
data.Generator=Generator;

%初值
iF0 =data.Generator.VF/Generator.Rf;%励磁绕组初始电流
id0_stast=Generator.Lmd*iF0/((Generator.Lmd+Generator.Llou)+((Generator.Rs+Generator.R)/Generator.w)^2/(Generator.Lmq+Generator.Llou));
iq0_stast=(Generator.Rs+Generator.R)/(Generator.Lmq+Generator.Llou)/Generator.w*id0_stast;
i_start = [-id0_stast; -iq0_stast; 0; iF0; 0; 0;]; % Initial currents电压初值

Generator_Cal=@(tspan,i0) funwrapper2(@Gllshort_si,tspan,i0,data.Generator);%
pi2=2.*pi/3;
%励磁控制器
data.Generator.Kp=0.008;%0.05
data.Generator.Ki=0.002;
data.Gene_PI_in=Generator.VF;
data.Gene_int_error=0;
%求解设置
t0=0; tfinal = 20;
data.Gene_deltat=0.04;%整机迭代步长
tend=data.Gene_deltat;

time=[];ueff=[];Pge=[];Iall=[];Ufall=[];Ia_all=[];Id_all=[];Iq_all=[];Pe=[];T=[];time_select=[];
while 1
%     if t0>=3
%         data.Generator.w=Generator.w*1.03;
%     else
%         data.Generator.w=Generator.w;
%     end)
    if t0>=2
        data.Generator.R=80;
    else
        data.Generator.R=Generator.R;
    end
    
    tspan=t0:0.0005:tend; 
    t0=tend;
    tend=t0+data.Gene_deltat;
    Generator_Cal=@(tspan,i0) funwrapper2(@Gllshort_si,tspan,i0,data.Generator);%
    [t,i] = ode23s(Generator_Cal, tspan, i_start); % use for MATLAB 5
    id=-i(1:(end-1),1); iq=-i(1:(end-1),2);i0=-i(1:(end-1),3);iF=i(1:(end-1),4); iD=i(1:(end-1),5); iQ=i(1:(end-1),6);
    i_start=[-id(end);-iq(end);-i0(end);iF(end);iD(end);iQ(end)];
    %current dq0 to current abc
    nn=length(id);
    w=data.Generator.w;
    for kk=1:nn
        tt=t(kk);
        thetaa=w*tt;
        thetab=thetaa-pi2;
        thetac=thetaa+pi2;
        ia(kk)=cos(thetaa)*id(kk)-sin(thetaa)*iq(kk)+i0(kk);
        ib(kk)=cos(thetab)*id(kk)-sin(thetab)*iq(kk)+i0(kk);
%         ic(kk)=cos(thetac)*id(kk)-sin(thetac)*iq(kk)+i0(kk);
    end
    Ufall=[Ufall,data.Generator.VF];
    Ia_all=[Ia_all;iF];
    Id_all=[Id_all;id];
    Iq_all=[Iq_all;iq];
    ueff_i=sqrt(0.5*Id_all(end).^2+0.5*Iq_all(end).^2)*data.Generator.R;%端电压有效值，与整机时间步同频
%     [time_i,ueff_i]=CalcuRMS(t,ia*data.Generator  .R,length(tspan)); 
    
     [data.Generator.VF_real,data.Gene_int_error]=GenePID(data.Generator.Udemand,ueff_i,data);
     try
         data.Generator.VF=data.Generator.VF_real+(data.Generator.VF_old-data.Generator.VF_real)*exp(-data.Gene_deltat/2);
         data.Generator.VF_old=data.Generator.VF;
     catch
         data.Generator.VF=data.Generator.VF_real;
         data.Generator.VF_old=data.Generator.VF;
     end
     
    ieff_i=ueff_i./data.Generator.R;
    time=[time,tspan(1:(end-1))];
    time_select=[time_select,tspan(end-1)];
    ueff=[ueff,ueff_i];
%     Pge=[Pge,3*ieff_i*ueff_i+3*ieff_i*ieff_i*data.Generator.Rs];%这样算不对
    Pe=[Pe,1.5*(id(end)^2*data.Generator.R+iq(end)^2*data.Generator.R)];%输出功率
    Iall=[Iall,ieff_i];
    F=L*(i(end-1,:)');%磁通量
    F_d=F(1);
    F_q=F(2);
    T=[T,-1.5*F_d*i(end-1,2)+1.5*F_q*i(end-1,1)];
    if t0>tfinal
        break;
    end
end

figure
plot(time_select,ueff)
xlabel('时间/s')
ylabel('输出端电压有效值/V')
figure
plot(time_select,Ufall)
xlabel('时间/s')
ylabel('励磁电压/V')

% figure
% plot(time,Pge)
% xlabel('时间/s')
% ylabel('功率/W')
% figure
% plot(time,Id_all)
% xlabel('时间/s')
% ylabel('Id/A')
% figure
% plot(time,Iq_all)
% xlabel('时间/s')
% ylabel('Iq/A')
figure
plot(time_select,Ufall)
xlabel('时间/s')
ylabel('励磁电压/V')


figure
plot(time,Ia_all)
xlabel('时间/s')
ylabel('电流瞬时值/A')

figure
plot(time_select,Pe)
xlabel('时间/s')
ylabel('Pe/pu')

figure
plot(time_select,T)
xlabel('时间/s')
ylabel('T/pu')