% 涡轮盘腔测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
BC.Td=800;
N=2;
[data.Geo,data.boundary]=Turbine_Cavity_Set(BC,N);
data.RES=[0 5000];
data.Cons=Cons_set();
W=1;
GasOut=TRC2Arm(GasIn,W,data)


