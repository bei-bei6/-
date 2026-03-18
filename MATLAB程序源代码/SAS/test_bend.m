% 弯头测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

data.d=0.02;
data.r=0.2;
data.theta=60;
data.roughness=1e-5;
data.Cons=Cons_set();

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=200e3;
Bend_Circular(GasIn,Psout,data)