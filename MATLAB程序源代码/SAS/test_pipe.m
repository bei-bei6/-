% 管道单元测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
%
data.CASE1.L=0.215;
data.CASE1.theta=0;
data.CASE1.d=0.018;
data.CASE1.roughness=9.0000e-05;
data.CASE1.RES=0;
data.CASE1.N=10;
data.CASE1.Tw=500*ones(1,data.CASE1.N); 
data.CASE1.Num=1;
data.CASE1.ST='incompressible';%'compressible';
data.CASE1.type=0;%0='Adiabatic';
data.CASE1.Cons=Cons_set();

data.GasIn.Pt=221.130e3;
data.GasIn.Tt=369.92;
data.GasIn.Swirl=0;
data.Psout=148.131e3;
[Pipe1O,Pipe1D]=Pipe(data.GasIn,data.Psout,data.CASE1);
% flip(Pipe1D.Ma);


