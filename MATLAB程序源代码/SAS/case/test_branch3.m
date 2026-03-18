%% 支路3：低压涡轮静叶冷却支路 W=1.7557+0.7023=2.458
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));

data.BC.GasPrimary.W=35.114;
%data.BC.GasPrimary.Pt=1529248.446;
data.BC.GasPrimary.Tt=1.1767e3;
% 低压涡轮静叶冷却支路进口总压总温
data.BC.Pt1=1.348064718249001e+06; % Pa
data.BC.Tt1=6.193509181406739e+02; % K

% 排气点参数
data.BC.Pamb1=362774.942*0.9; % 低压涡轮静叶前总压*0.9，Pa
data.BC.Pamb2=107422.699*0.9; % 低压涡轮静叶前总压*0.9，Pa
data.BC.HP_Shaft=13130; % 高压涡轮转速，rpm
data.BC.LP_Shaft=6000; % 低压涡轮转速，rpm

%压力初值
x0=[1125905.72717828;918310.674597183;807972.523820245];
%%
sas=@branch_3;
FUN=@(x) funwrapper(sas,x,data);
opt.maxiter=5000;
opt.tolfun=1e-6;
opt.tolx=1e-12;
icount=1;imax=50;
bounds=[0 data.BC.Pt1
0 data.BC.Pt1
0 data.BC.Pt1];

[x, ithist]=broyden(FUN,x0,opt,bounds);%
[NErr,SAS_Data]=branch_3(x,data);
W(1)=SAS_Data.FH3_1O.W; %branch 3
W(2)=SAS_Data.rimseal3_1O.W %branch 4