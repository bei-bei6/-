%% 0时刻稳态点求解
% data.HPCvalve=0;
for j=1:length(x0_sheet)
    x0(j,1)=interp1g(-data.Power_d.*[1:-0.2:0.2],x0_sheet(j,:),data.Load);
end
if data.PT_Shaft~=dp.LPSpeed
    PT_Shaft_in_table=linspace(dp.LPSpeed,data.PT_Shaft,5);
else
    PT_Shaft_in_table=data.PT_Shaft;
end
for PT_Shaft_in=PT_Shaft_in_table
    data.Metal_open=0;
    data.PT_Shaft=PT_Shaft_in;
    aircraft=@engine_SS;
    FUN=@(x) funwrapper(aircraft,x,data);
    opt.maxiter=1000;%最大迭代次数
    opt.tolfun=1e-7;%收敛容差
    opt.tolx=1e-12;%最小变化量
    bounds=[10 100
        -0.3 1.1
        0 0.3
        -0.3 1.1
        -0.3 1.1
        0 20000
        ];
    if data.HGC.SAS,bounds=[bounds;1e5,5e6];else x0(end)=[];end
    [x, ithist]=broyden(FUN,x0,opt,bounds);%,bounds
    [~,GasPth,WholeEngine]=engine_SS(x,data);
    x0=x;
end
%给定初始瞬态计算初值
Wf0=WholeEngine.B_Data.Wf;
data.Wf=Wf0;
data.Wf_old=data.Wf;
HP_Shaft0=x(6);
data.HP_Shaft=HP_Shaft0;
data.HPCvalve=0;
data.HPTvalve=0;
x0=[x(1);x(2);x(4);x(5)];%压气机入口流量，HPC、HPT、PTbeta
data.Metal.T_HPC=0.5*(GasPth.GasOut_Inlet.Tt+GasPth.GasOut_HPC.Tt);
data.Metal.T_HPT=0.5*(GasPth.GasOut_Burner.Tt+GasPth.GasOut_HPT.Tt);
data.Metal.T_LPT=0.5*(GasPth.GasOut_HPT.Tt+GasPth.GasOut_PT.Tt);

initial.x0=x0;
initial.Wf0=Wf0;
initial.HP_Shaft0=HP_Shaft0;