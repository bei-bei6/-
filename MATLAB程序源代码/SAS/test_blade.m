% 叶片冷却单元测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

SAS.Blade.Num=22;
SAS.Blade.L=0.0468;
SAS.Blade.theta=0;
SAS.Blade.d=0.025/3;
SAS.Blade.roughness=0.0050*SAS.Blade.d;
SAS.Blade.RES=0;
SAS.Blade.N=3;
SAS.Blade.Tw=0*ones(1,SAS.Blade.N);
SAS.Blade.ST='compressible';
SAS.Blade.type=0;%0='Adiabatic';
SAS.Blade.Cons=Cons_set();
% 冷却模型几何参数
SAS.Blade.Alet=pi*(SAS.Blade.d/2)^2;
SAS.Blade.Ag=SAS.Blade.Num*2*pi*(SAS.Blade.d/2)*SAS.Blade.L;
SAS.Blade.Ath=0.05;
% 传热模型
SAS.Blade.eta_c=0.6;
SAS.Blade.eta_f=0.7;
SAS.Blade.hg=1420;
SAS.Blade.delta_tbc=1.8e-4;
SAS.Blade.delta_bw=0.0013;
SAS.Blade.k_tbc=1.8;
SAS.Blade.k_bw=13;

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=148.131e3;
GasPrimary.W=30;%主燃流量
GasPrimary.Tt=1900;%主燃温度

[bladeO,bladeD]=blade(GasIn,GasPrimary,Psout,SAS.Blade);
