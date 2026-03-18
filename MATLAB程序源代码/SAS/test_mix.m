% 混合/分流测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

GasIn1.W=1;
GasIn1.Pt=221.130e3;
GasIn1.Tt=369.92;
GasIn1.Swirl=0;

GasIn2.W=2;
GasIn2.Pt=421.130e3;
GasIn2.Tt=569.92;
GasIn2.Swirl=0.6;

Mix(GasIn1,GasIn2)
Splitter(GasIn1,[0.2 0.8]);