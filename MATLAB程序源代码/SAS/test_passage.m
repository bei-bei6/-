% 旋转通道测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
%%
data.d1=0.01;
data.d2=0.02;
data.RESI=1000;
data.RESO=2000;
data.Two=800;
data.Cons=Cons_set();
data.Node1.x=0;data.Node1.y=0;data.Node1.z=0;
data.Node2.x=0.1;data.Node2.y=0;data.Node2.z=0;
data.N=5;
data.Num=2;
data.roughness=1e-5;
data.type=1;

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=201e3;
RAP(GasIn,Psout,data)
%
data.Tw=800;
data.d=0.02;
data.RES=2000;
RP(GasIn,Psout,data)
