% 瞬态计算结果处理说明文档

clc,clear,close all
addpath(genpath('.\result'));
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\Generator'));
addpath(genpath('.\parameter'));
load([pwd,'/parameter/MAP.mat'])        %部件特性图
load([pwd,'/parameter/scale.mat'])      %缩放系数
load([pwd,'/result/GasPth1.mat']);      %流路数据
load([pwd,'/result/WholeEngine1.mat']); %部件数据
load([pwd,'/result/TIME.mat']);         %时间
load([pwd,'/result/Data.mat']);         %设定值         
%% 参数说明
%{
%（1）
%WholeEngine保存了部件内部的计算参数，在计算程序中，在engine_DS1.m和engine_DS_NoSAS_LIMITall.m中定义了WholeEngine1内部的参数，具体包括
WholeEngine1.Inlet_Data;            %进气道参数
WholeEngine1.HPCData;               %高压压气机参数
WholeEngine1.B_Data;                %燃烧室参数
WholeEngine1.HPTData;               %高压涡轮参数
WholeEngine1.PTData;                %动力涡轮参数
WholeEngine1.HP_Shaft;              %高速轴转速
WholeEngine1.HP_Shaftcor;           %高速轴换算转速
WholeEngine1.PT_Shaft;              %动力轴换算转速
WholeEngine1.before_PT;             %动力涡轮前支板结构
WholeEngine1.after_PT;              %动力涡轮后支板结构
WholeEngine1.Deflate.HPTvalve;      %放气系统
WholeEngine1.Others.Xdot_HPShaft;   %核心机升转速率
WholeEngine1.Others.Xdot_PTShaft;   %动力轴升转速率
WholeEngine1.Others.Load;           %负载

%每个部件内的参数可查看相应的部件模型程序，例如压气机可查看 HPC.m 文件中WholeEngine1.HPCData的定义
Data.SM = SM;%喘振裕度
Data.WIn = WIn;%进气流量
Data.Wcin = Wc;%进气换算流量
Data.Nc = Nc;%换算转速
Data.PR = PR;%压比
Data.Eff=Eff;%效率
Data.Ncor_r = Ncor_r;%相对换算转速
Data.WcMap = WcMap;%压气机特性图中的流量
Data.PRMap = PRMap;%压气机特性图中的压比
Data.EffMap = EffMap;%压气机特性图中的效率
Data.SurgePR = Surge_PR;%喘振点压比
Data.Wbleeds = W_bleeds;%引起量
Data.Pwrb4bleed = Pwrour_t;%不考虑引气时候的压气机功率
Data.PwrBld = Power_bleeds;%引气导致的功率损失
Data.Pwrout = Pwrout;%实际出口流量
Data.Test = 0;
Data.Nmech=Nmech;%转速
Data.W_3=GasOut_HPC.W+WIn*(data.SAS.Ratio(1)+data.SAS.Ratio(2));%出口流量

%对每个参数可进行如下方式的调用，例如，第1个时间步的压气机喘振裕度
WholeEngine1(1).HPCData.SM

%（2）
%GasPth1保存了部件进出口的总温，总压，流量，总焓和油气比，在engine_DS1.m和engine_DS_NoSAS_LIMITall.m中定义了GasPth1内部的参数，具体包括
GasPth1.GasOut_Inlet;          %进气道出口
GasPth1.GasOut_HPC;              %压气机出口
GasPth1.GasOut_Burner;         %燃烧室出口
GasPth1.GasOut_HPT;              %高压涡轮出口
GasPth1.GasOut_PT;                %动力涡轮出口
GasPth1.Volute;                    %排气蜗壳出口
GasPth1.DeflateDuct.Pt;  %用于valve中放气阀初始状态计算
GasPth1.DeflateDuct.Tt;  %用于valve中放气阀初始状态计算
GasPth1.DeflateDuct.W;           %放气系统
%每个部件内的参数:W 流量，ht 总焓，Tt 总温，Pt 总压，FAR 油气比。例如，第1个时间步的压气机出口温度定义为
GasPth1.GasOut_HPC.Tt

%（3）
%TIME保存了时间量，具体包括：
TIME.deltat;%时间步长
TIME.num;%时间步数
TIME.time;%每个时间步对应的时间
%}
%% 例1：查看压气机喘振裕度
%将WholeEngine1内的喘振裕度提取到SM中
for j=1:length(WholeEngine1)
    SM(j)=WholeEngine1(j).HPCData.SM;
end
%绘图
figure
plot(0:data.deltat:(length(SM)-1)*data.deltat,SM,'LineWidth',1.2)%data.deltat为时间步长，等于TIME.deltat
ylabel('喘振裕度/%')
xlabel('时间/s')
grid on
%% 例2：查看燃烧室出口温度，并考虑传感器延迟的影响
%将GasPth1内的燃烧室出口问题提取到T4中
for j=1:length(GasPth1)
    T4(j)=GasPth1(j).GasOut_Burner.Tt;
end
%传感器延迟函数inertia
T4_delay=inertia(0:data.deltat:(length(T4)-1)*data.deltat,T4,1);
figure
hold on
plot(0:data.deltat:(length(T4)-1)*data.deltat,T4,'LineWidth',1.2)
plot(0:data.deltat:(length(T4_delay)-1)*data.deltat,T4_delay,'LineWidth',1.2)
ylabel('T4/K')
xlabel('时间/s')
legend('无延迟','延迟1s')
grid on
%% 例3：查看动力轴转速和核心机升转速率
%动力轴转速
for j=1:length(WholeEngine1)
    PT_Shaft_all(j)=WholeEngine1(j).PT_Shaft;
end
figure
plot(0:data.deltat:(length(PT_Shaft_all)-1)*data.deltat,PT_Shaft_all,'LineWidth',1.2)
ylabel('低压轴转速/rpm')
xlabel('时间/s')
set(gca,'FontSize',12);
grid on

%核心机升转速率
for j=1:length(WholeEngine1)
    Xdot_HPShaft_all(j)=WholeEngine1(j).Others.Xdot_HPShaft;
    maxXdot_HPShaft_all(j)=WholeEngine1(j).Others.maxXdot_HPShaft;
    minXdot_HPShaft_all(j)=WholeEngine1(j).Others.minXdot_HPShaft;
end
figure
plot(0:data.deltat:(length(Xdot_HPShaft_all)-1)*data.deltat,Xdot_HPShaft_all,'k-','LineWidth',1.2)
hold on
plot(0:data.deltat:(length(maxXdot_HPShaft_all)-1)*data.deltat,maxXdot_HPShaft_all,'r--','LineWidth',1.2)
plot(0:data.deltat:(length(minXdot_HPShaft_all)-1)*data.deltat,minXdot_HPShaft_all,'b--','LineWidth',1.2)
legend('实际升/降转速率','临界升转速率','临界降转速率')
xlabel('时间/s')
ylabel('核心机升/降转速率/(rpm/s)')
set(gca,'FontSize',12);
grid on

%% 例4：绘制部件特性图
i=length(WholeEngine1);                 %每个时间步保存一个WholeEngine1数值，因此WholeEngine1长度等于总的时间步数

scalar.HPC=[scale.HPC.Wc scale.HPC.PR scale.HPC.Eff scale.HPC.Nc];
scalar.HPT=[scale.HPT.Wc scale.HPT.PR scale.HPT.Eff scale.HPT.Nc];
scalar.PT=[scale.PT.Wc scale.PT.PR scale.PT.Eff scale.PT.Nc];
%绘制压气机特性图
figure
hold on
PlotCMap(MAP.HPC.Nc, MAP.HPC.Wc, MAP.HPC.PR, MAP.HPC.Eff,MAP.HPC.Rline,scalar.HPC)
for j=1:i
    plot(WholeEngine1(j).HPCData.Wcin,WholeEngine1(j).HPCData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',2)
end
%绘制高压涡轮特性图
figure
PlotTMap(MAP.HPT.Nc, MAP.HPT.Wc, MAP.HPT.PR, MAP.HPT.Eff,scalar.HPT)
for j=1:i
plot(WholeEngine1(j).HPTData.Wc,WholeEngine1(j).HPTData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',2)
end
%绘制动力涡轮特性图
figure
PlotTMap(MAP.PT.Nc, MAP.PT.Wc, MAP.PT.PR, MAP.PT.Eff,scalar.PT)
for j=1:i
plot(WholeEngine1(j).PTData.Wc,WholeEngine1(j).PTData.PR,'rs','MarkerSize',6,'MarkerFaceColor','y','LineWidth',2)
end