% 旋转孔测试程序
clc,clear,close All
addpath(genpath('.\Solver'));
addpath(genpath('.\SAS'));
addpath(genpath('.\thermo'));
i=1;
for x=1e5:1e4:5e5
    GasIn.Pt=5e5;
    GasIn.Tt=300;
    GasIn.Swirl=0;
    Psout=x;
    
    data.Num=5;
    data.D=0.01;
    data.rf=0.002;
    data.L=0.02;
    data.beta=45/180*pi;
    data.theta0=0;
    data.Cons=Cons_set();
    
    [GasOut,~]=Hole(GasIn,Psout,data);
    W(i)=GasOut.W;
    i=i+1;
end
plot(1e5:1e4:5e5,W)

