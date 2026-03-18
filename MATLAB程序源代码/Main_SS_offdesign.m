%稳态计算程序：控制核心机转速
clc,clear,close All
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\parameter'));
warning off
load([pwd,'/parameter/MAP.mat'])
load([pwd,'/parameter/scale.mat'])
load([pwd,'/parameter/character.mat'])
data.scale=scale;data.HPCdate=HPCdate;data.HPTdate=HPTdate;data.PTdate=PTdate;
load([pwd,'/parameter/dp.mat'])
load([pwd,'/parameter/x0.mat'])
x0(6)=[];
% load('dp')
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
HighPresure_Shaft=14000*(1);
%%
basic_setting;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%部件特性修正表
data.Correction.HPC.Nc=[6000,20000];
data.Correction.HPC.W=[1,1];
data.Correction.HPC.Eff=[1,1];
data.Correction.HPC.PR=[1,1];

data.Correction.HPT.Nc=[6000,20000];
data.Correction.HPT.W=[1,1];
data.Correction.HPT.Eff=[1,1];
data.Correction.HPT.PR=[1,1];

data.Correction.LPT.Nc=[6000,20000];
data.Correction.LPT.W=[1,1];
data.Correction.LPT.Eff=[1,1];
data.Correction.LPT.PR=[1,1];
%% 整机子程序
Power=[];z=[];SFC=[];W_in=[];T4_all=[];TEff=[];
i=0;
for HP_Shaft=HighPresure_Shaft
    i=i+1;
    data.HP_Shaft=HP_Shaft;
    aircraft=@engine_SS_offdesign;
    FUN=@(x) funwrapper(aircraft,x,data);
    opt.maxiter=1000;%最大迭代次数
    opt.tolfun=1e-7;%收敛容差
    opt.tolx=1e-12;%最小变化量
    bounds=[10 100
        -0.3 1.1
        0 0.3
        -0.3 1.1
        -0.3 1.1
        ];
    if data.HGC.SAS
        bounds=[bounds;1e5,5e6];
        if i==1
            x0(6,1)=2e6;
        end
    end

    [x, ithist]=broyden(FUN,x0,opt,bounds);%,bounds
    [~,GasPth(i),WholeEngine(i)]=engine_SS_offdesign(x,data);
    x0=x;
    fprintf('%s%0.2f%s\n','当前输出功率',WholeEngine(i).PTData.Pwrout/1000,'kW')
    Power=[Power,WholeEngine(i).PTData.Pwrout];
    a=WholeEngine(i).PTData.Pwrout;
    b=WholeEngine(i).B_Data.heat;
    hy=x0(3)*GasPth(i).GasOut_HPC.W/(WholeEngine(i).PTData.Pwrout)*1000*3600;
    TEff=[TEff,WholeEngine(i).PTData.Pwrout/(WholeEngine(i).B_Data.heat)];
    SFC=[SFC,hy];
    W_in=[W_in,GasPth(i).GasOut_HPC.W];
    T4_all=[T4_all,GasPth(i).GasOut_Burner.Tt];
end
scalar.HPC=[scale.HPC.Wc scale.HPC.PR scale.HPC.Eff scale.HPC.Nc];
scalar.HPT=[scale.HPT.Wc scale.HPT.PR scale.HPT.Eff scale.HPT.Nc];
scalar.PT=[scale.PT.Wc scale.PT.PR scale.PT.Eff scale.PT.Nc];

figure
hold on
PlotCMap(MAP.HPC.Nc, MAP.HPC.Wc, MAP.HPC.PR, MAP.HPC.Eff,MAP.HPC.Rline,scalar.HPC)

for j=1:i
    plot(WholeEngine(j).HPCData.Wcin,WholeEngine(j).HPCData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',1)
end
figure
PlotTMap(MAP.HPT.Nc, MAP.HPT.Wc, MAP.HPT.PR, MAP.HPT.Eff,scalar.HPT)
for j=1:i
plot(WholeEngine(j).HPTData.Wc,WholeEngine(j).HPTData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',1)
end

figure
PlotTMap(MAP.PT.Nc, MAP.PT.Wc, MAP.PT.PR, MAP.PT.Eff,scalar.PT)
for j=1:i
plot(WholeEngine(j).PTData.Wc,WholeEngine(j).PTData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',1)
end

%% 特性检查
for j=1:length(WholeEngine)
    Rline_HPC(j)=WholeEngine(j).HPCData.Rline;
    Rline_HPT(j)=WholeEngine(j).HPTData.Rline;
    Rline_PT(j)=WholeEngine(j).PTData.Rline;
end
if any(Rline_HPC>1)||any(Rline_HPC<0)
    fprintf('警告：工作点超出压气机特性图范围\n')
end
if any(Rline_HPT>1)||any(Rline_HPT<0)
    fprintf('警告：工作点超出高压涡轮特性图范围\n')
end
if any(Rline_PT>1)||any(Rline_PT<0)
    fprintf('警告：工作点超出动力涡轮特性图范围\n')
end
%%

OUTPUT=[Power;W_in;SFC;T4_all]';
% i=1;
A2=[1,  GasPth(i).GasOut_Inlet.W,  data.T0,  data.P0;%入口
    2,  GasPth(i).GasOut_Inlet.W,  GasPth(i).GasOut_Inlet.Tt,  GasPth(i).GasOut_Inlet.Pt;%进气道出口
    3,  WholeEngine(i).HPCData.W_3,  GasPth(i).GasOut_HPC.Tt,  GasPth(i).GasOut_HPC.Pt;    %压气机出口（不含引气）
    31,  GasPth(i).GasOut_HPC.W,  GasPth(i).GasOut_HPC.Tt,  GasPth(i).GasOut_HPC.Pt;    %燃烧室入口=含引气量的压气机出口
    4,  GasPth(i).GasOut_Burner.W,  GasPth(i).GasOut_Burner.Tt,  GasPth(i).GasOut_Burner.Pt;    %燃烧室出口 
    41,  WholeEngine(i).HPTData.W41,  WholeEngine(i).HPTData.T41,  WholeEngine(i).HPTData.P41;    %HPT喷嘴后    
    43,  WholeEngine(i).HPTData.W43,  WholeEngine(i).HPTData.T43,  WholeEngine(i).HPTData.P43;    %HPT动叶后 （气体未混合）     
    44,  GasPth(i).GasOut_HPT.W,  GasPth(i).GasOut_HPT.Tt,  GasPth(i).GasOut_HPT.Pt;    %HPT后   （气体混合）     
    45,  WholeEngine(i).PTData.W45,  WholeEngine(i).PTData.T45,  WholeEngine(i).PTData.P45;    %LPT喷嘴后    
    49,  WholeEngine(i).PTData.W49,  WholeEngine(i).PTData.T49,  WholeEngine(i).PTData.P49;    %LPT动叶后 （气体未混合）     
    5,  GasPth(i).GasOut_PT.W,  GasPth(i).GasOut_PT.Tt,  GasPth(i).GasOut_PT.Pt;    %LPT后   （气体混合）     
    6,  GasPth(i).Volute.W6,  GasPth(i).Volute.T6,  GasPth(i).Volute.P6;    %LPT支板后        
    8,  GasPth(i).Volute.W6,  GasPth(i).Volute.T6,  GasPth(i).Volute.P6];    %流经排气蜗壳后流量和滞止参数不变      

fprintf('               W              T             P\n')
fprintf('Station       kg/s            K             kPa\n')
formatSpec = ' %2.0f         %5.3f        %7.2f       %7.3f   \n';
fprintf(formatSpec,A2')
fprintf('-----------------------------------------------------\n')
fprintf('                  效率           压比\n')
A3=[WholeEngine(i).HPCData.Eff WholeEngine(i).HPCData.PR;
    WholeEngine(i).B_Data.Eff WholeEngine(i).B_Data.PR;
    WholeEngine(i).HPTData.Eff WholeEngine(i).HPTData.PR;  
    WholeEngine(i).PTData.Eff WholeEngine(i).PTData.PR];

formatSpec =' %5.4f        %5.4f        \n';
fprintf('压气机            ')
fprintf(formatSpec,A3(1,:))
fprintf('燃烧室            ')
fprintf(formatSpec,A3(2,:))
fprintf('高压涡轮          ')
fprintf(formatSpec,A3(3,:))
fprintf('动力涡轮          ')
fprintf(formatSpec,A3(4,:))
fprintf('-----------------------------------------------------\n')
formatSpec =' %8.2f';
fprintf('输出功率=')
fprintf(formatSpec,Power(i)/1000)
fprintf(' kW\n')
formatSpec =' %8.6f';
fprintf('热效率=')
fprintf(formatSpec,TEff(i))
fprintf('\n')
fprintf('高速轴转速=')
HP_Shaft=data.HP_Shaft;
fprintf(formatSpec,HP_Shaft)
fprintf(' rpm')
fprintf('\n')




