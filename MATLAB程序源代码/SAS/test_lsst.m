% 管道单元测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
%
data.NT=5;
data.Rsi=0.15;%shaft radius
data.Cri=0.3e-3; %radial Clearance 
data.Li=4e-3; %Labyrith seal  Pitch
data.ti=2e-3; %Labyrith seal tooth Tip length
data.Bi=5e-3;%Labyrith seal tooth height
data.RS=4835;%rpm
data.Pos='Rotor';
data.Method='explicit';%'explicit';
data.Cons=Cons_set();

GasIn.Pt=221.130e3;
GasIn.Tt=369.92;
GasIn.Swirl=0;
Psout=148.131e3;
LSST(GasIn,Psout,data)