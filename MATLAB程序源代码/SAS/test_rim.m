% 轮缘封严测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
%
data.N=2;
data.Sc_ax=0.3e-3;
data.B=0.2e-3;
data.Sc_rad=0.3e-3;
data.S_buffer=0.9e-3;
data.b=0.25;
data.Cons=Cons_set();

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=148.131e3;
rimseal(GasIn,Psout,data)



