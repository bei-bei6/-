%性能自适应
clc,clear,close All
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\parameter'));
addpath(genpath('.\SAS_JMH2'));
warning off
load([pwd,'/parameter/MAP.mat'])
load([pwd,'/parameter/scale.mat'])
load([pwd,'/parameter/character.mat'])
data.scale=scale;data.HPCdate=HPCdate;data.HPTdate=HPTdate;data.PTdate=PTdate;
load([pwd,'/parameter/dp.mat'])
load([pwd,'/parameter/x0_sheet.mat'])
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
%初始值
data.Correction.SAS_ratio=[1,1,1,1];
data.Correction.T_delta=[0,0,0,0];%
data.Correction.Position=[1,1];%
data.Correction.Combustor_P=1;%
data.Correction.Combustor_eff=1;%
data.Correction.HPC.Power=1;%
data.Correction.LPT.Power=1;%
data.P_loss_inlet=0;      %
data.P_loss_volute=0;      %
data.Correction.HPC_W=1;
data.Correction.HPC_Eff=1;
data.Correction.HPC_PR=1;
data.Correction.HPT_W=1;
data.Correction.HPT_Eff=1;
data.Correction.LPT_W=1;
data.Correction.LPT_Eff=1;
%部件特性修正表
data.Correction.HPC.Nc=[6000,20000];
data.Correction.HPC.W=[1,1].*data.Correction.HPC_W;
data.Correction.HPC.Eff=[1,1].*data.Correction.HPC_Eff;
data.Correction.HPC.PR=[1,1].*data.Correction.HPC_PR;

data.Correction.HPT.Nc=[6000,20000];
data.Correction.HPT.W=[1,1].*data.Correction.HPT_W;
data.Correction.HPT.Eff=[1,1].*data.Correction.HPT_Eff;
data.Correction.HPT.PR=[1,1];

data.Correction.LPT.Nc=[6000,20000];
data.Correction.LPT.W=[1,1].*data.Correction.LPT_W;
data.Correction.LPT.Eff=[1,1].*data.Correction.LPT_Eff;
data.Correction.LPT.PR=[1,1];

data.Correction.Burner.Nc=[0.6,1];
data.Correction.Burner.Eff=[1,1].*data.Correction.Combustor_eff;
data.Correction.Burner.PR=[1,1].*data.Correction.Combustor_P;
%% 基本参数
data.T0=288.15;         %入口总温/K
data.P0=101325;         %入口总压/Pa
data.PT_Shaft=6000;     %动力轴转速
data.RH=0;              %相对湿度/[0,1]
%% 进气道
data.P_loss_inlet=0;      %进气总压损失修正
%% 高压压气机
%% 燃烧室
data.HGC.Burner=0;
data.Combustor.x=0.12;
data.Combustor.y=0;
%% 高压涡轮
data.HGC.HPT=0;        %是否对高压涡轮进行修正
data.HPTstage=2;       %级数
data.HPT_OTDF=3;       %OTDF修正
data.HPT_Clearance=5;  %叶尖间隙修正
data.HPT_duct.Rout=500;% 过渡段出口顶部半径 [mm]~[300 599]	
data.HPT_duct.Rratio=0.8;% 过渡段进/出口顶部半径比~[0.60, 0.99]	
data.HPT_duct.lgb_in=0.8;% 过渡段进口轮毂比~[0.70, 0.92]		
data.HPT_duct.lgb_out=0.8;% 过渡段出口轮毂比~[0.75, 0.94]		
data.HPT_duct.lr=1;% 过渡段流向长度/出口顶部半径~[0.20, 1.20]	
%% 排气系统
data.P_loss_volute=0;      %排气总压损失修正
%% 空气系统
data.SAS.Position =[1;1;0.822;0.548];           %引气位置：高导，高转，动导，动转
data.SAS.Ratio =[0.09;0.05;0.05;0.02];   %引气比例：高导，高转，动导，动转
data.HGC.SAS=0; %使用流体网络法计算空气系统特性
%% 放气系统
data.HPCDeflate.Position=1;     %压气机放气位置
data.HPCDeflate.Ratio=0.0002;      %压气机放气量
data.HPTDeflate.Ratio=0;      %高压涡轮后放气量
%% 高压轴
data.HPS.J=14.96;      %转动惯量
%% 低压轴
data.LPS.J=318;      %转动惯量
%% 燃机风阻损失(正数/W)
data.loss=0;
data.Metal_open=0; %是否计算热惯性
%%
basic_setting;
%%
load([pwd,'/result/TestData1.mat'],'TestData')
data.Data=TestData;
data.dp=dp;
data.x0_sheet=x0_sheet;


x0 = [ones(1,7)*1,0,1];
lb=[0.90*ones(1,7),-1000];
ub=[1.1*ones(1,7),5000];
aircraft=@cal_dp;
FUN=@(x) funwrapper(aircraft,x,data);
options = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective');
options.StepTolerance=1e-50;%  options.Algorithm = 'levenberg-marquardt';% options.Display='off';'trust-region-reflective'
%lm方法无法设置lb和ub，'trust-region-reflective'无法解决欠定和超定
x_all=[];residual_all=[];x_all_fine=[];residual_all_fine=[];
[x,resnorm,residual]= lsqnonlin(FUN,x0,[],[],options);
fprintf('部件修正系数=[%s]\n',num2str(x,'%f  '));
fprintf('修正后各参数相对误差（%%）=[%s]\n',num2str(residual'*100,'%f  '));

%{
try
    x = lsqnonlin(FUN,x0,lb,ub,options)

catch
    for w=1:5
        try
            x0=lb+rand(1,length(x0)).*(ub-lb);
            [x,resnorm,residual] = lsqnonlin(FUN,x0,lb,ub,options);
            x_all=[x_all;x];
            residual_all=[residual_all;residual'];
            if max(abs(residual))<0.005
                x_all_fine=[x_all_fine;x];
                residual_all_fine=[residual_all_fine;residual'];
            end
            if max(abs(residual))<0.001
                break
            end        
        end
    end
end
X=[0.9536    0.9555    0.9697    0.9651    0.9600    0.9600    0.9600   -0.0000    0.9504];
y=cal_dp(X,data)
%}
%%
 function y=cal_dp(X,data)
    %  
    dp=data.dp;
    x0_sheet=data.x0_sheet;
    %
    SW_HPC=X(1);%
    SE_HPC=X(2);%
    SP_HPC=1;%
    SW_HPT=median([0.95,X(3),1.05]);
    SE_HPT=X(4);%
    SW_LPT=X(5);%
    SE_LPT=X(6);%
    SP_burner=X(9);%
    SE_burner=X(7);%
    SASr2=1;
    inlet_loss=0;
    outlet_loss=X(8);
    %%
    data.Correction.SAS_ratio=[1,SASr2,1,1];%
    data.Correction.T_delta=[0,0,0,0];%
    data.Correction.Position=[0,0];%
    data.Correction.HPC.Power=1;%
    data.Correction.LPT.Power=1;%
    data.P_loss_inlet=inlet_loss;      %
    data.P_loss_volute=outlet_loss;    %
    %
    data.Correction.HPC.Nc=[6000,20000];
    data.Correction.HPC.W=[1,1].*SW_HPC;
    data.Correction.HPC.Eff=[1,1].*SE_HPC;
    data.Correction.HPC.PR=[1,1].*SP_HPC;
    
    data.Correction.HPT.Nc=[6000,20000];
    data.Correction.HPT.W=[1,1].*SW_HPT;
    data.Correction.HPT.Eff=[1,1].*SE_HPT;
    data.Correction.HPT.PR=[1,1];
    
    data.Correction.LPT.Nc=[6000,20000];
    data.Correction.LPT.W=[1,1].*SW_LPT;
    data.Correction.LPT.Eff=[1,1].*SE_LPT;
    data.Correction.LPT.PR=[1,1];
    
    data.Correction.Burner.Nc=[0.6,1];
    data.Correction.Burner.Eff=[1,1].*SE_burner;
    data.Correction.Burner.PR=[1,1].*SP_burner;
    %%
    i=0;
    for bianglian=-2e7*[1.0]
        Load=bianglian;
        i=i+1;   
        for j=1:length(x0_sheet)
            x0(j,1)=interp1g(-dp.PW.*[1:-0.2:0.2],x0_sheet(j,:),Load);
        end
        x0(end)=[];
        data.Load=Load;%输出功率
        aircraft=@engine_SS;
        FUN=@(x) funwrapper(aircraft,x,data);
        opt.maxiter=1000;%最大迭代次数
        opt.tolfun=1e-5;%收敛容差
        opt.tolx=1e-12;%最小变化量
    bounds=[10 100
        -0.3 1.1
        0 0.3
        -0.3 1.1
        -0.3 1.1
        0 20000
        ];
    
        [x, ithist]=broyden(FUN,x0,opt,bounds);%,bounds
        [~,GasPth(i),WholeEngine(i)]=engine_SS(x,data);
        x0=x;
    end
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%
%     Data=data.Data;
    for j=1:i
        Simu.P3(j)=GasPth(i).GasOut_HPC.Pt;
        Simu.T3(j)=GasPth(i).GasOut_HPC.Tt;
        Simu.T46(j)=GasPth(i).GasOut_HPT.Tt;
        Simu.P46(j)=GasPth(i).GasOut_HPT.Pt;
        Simu.T5(j)=GasPth(i).GasOut_PT.Tt;
        Simu.P5(j)=GasPth(i).GasOut_PT.Pt;
        Simu.Wf(j)=WholeEngine(i).B_Data.Wf;
        Simu.Q(j)=GasPth(i).GasOut_Inlet.W;
        Simu.Ng(j)=WholeEngine(i).HP_Shaft;
        Simu.T4(j)=GasPth(i).GasOut_Burner.Tt;
        Simu.SM(j)=WholeEngine(i).HPCData.SM;
    end
    j=1;
    %% 试验数据输入
    Data.P3=2.297810928903594e+06;
    Data.T3=7.545270968721729e+02;
    Data.T46=9.944172727992515e+02;
    Data.P46=4.064435291545852e+05;
    Data.T5=7.299512529046317e+02;
    Data.P5=1.116692123631551e+05;
    Data.Wf=1.680863147715385;
    Data.Ng=1.400005299400682e+04;

    Data.T3=Data.T3+10;
    Data.T46=Data.T46+10;
    Data.T5=Data.T5+20;
    %%
    error_1=[(Simu.P3(j)-Data.P3)/Data.P3
        (Simu.T3(j)-Data.T3)/Data.T3
        (Simu.T46(j)-Data.T46)/Data.T46
        (Simu.P46(j)-Data.P46)/Data.P46
        (Simu.T5(j)-Data.T5)/Data.T5
        (Simu.P5(j)-Data.P5)/Data.P5
        (Simu.Wf(j)-Data.Wf)/Data.Wf
        (Simu.Ng(j)-Data.Ng)/Data.Ng];
    
    y=[error_1]';
    
    fprintf('当前修正后参数相对误差（%%）=[%s]\n',num2str(y*100,'%f  '));

end

