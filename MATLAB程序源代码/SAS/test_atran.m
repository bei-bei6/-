% 转接头测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
%
data.d1=0.03;
data.d2=0.05;
data.Cons=Cons_set();

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=148.131e3;
ATran(GasIn,Psout,data)
data.L=0.1;
GTran(GasIn,Psout,data)


