%% 支路1：高压涡轮静叶冷却支路
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

% data.BC.GasPrimary.W=35.114;
data.BC.GasPrimary.Tt=1.1767e3;

% 高压涡轮静叶冷却支路进口总压总温
data.BC.Pt1=1.618043522549951e+06; % Pa
data.BC.Tt1=6.884101625264667e+02; % K

% 排气点参数
data.BC.Pamb1=1529248.446*0.9; % 高压涡轮静叶前总压*0.9，Pa


data.BC.HP_Shaft=13130; % 高压涡轮转速，rpm
data.BC.LP_Shaft=6000; % 低压涡轮转速，rpm
%压力初值
x0=[1422301.66382336;1484275.66664560;1411091.45879288];
%%
sas=@branch_1;
FUN=@(x) funwrapper(sas,x,data);
opt.maxiter=5000;
opt.tolfun=1e-6;
opt.tolx=1e-12;
icount=1;imax=50;
bounds=[0 data.BC.Pt1
0 data.BC.Pt1
0 data.BC.Pt1];

[x, ithist]=broyden(FUN,x0,opt,bounds);%
[NErr,SAS_Data]=branch_1(x,data);
W=SAS_Data.Hole1O.W