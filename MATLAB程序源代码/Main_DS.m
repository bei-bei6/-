%过渡态计算程序
tic
clc,clear,close All
addpath(genpath('.\Solver'));
selfchecking
warning off
load([pwd,'/parameter/MAP.mat'])
load([pwd,'/parameter/scale.mat'])
load([pwd,'/parameter/character.mat'])
data.scale=scale;data.HPCdate=HPCdate;data.HPTdate=HPTdate;data.PTdate=PTdate;%部件特性与缩放系数
load([pwd,'/parameter/dp.mat'])
load([pwd,'/parameter/x0_sheet.mat'])
load('HPS_Ndot_down')
load('HPS_Ndot_up')
%% 基本参数
data.T0=288.15;         %入口总温/K
data.P0=101325;         %入口总压/Pa
data.PT_Shaft=6000;     %动力轴转速
data.RH=0;              %相对湿度/[0,1]
%% 进气道
data.P_loss_inlet=0;      %进气总压损失修正
%% 高压压气机
%% 燃烧室
data.fuel_delay=0;     %燃油延迟
data.fuel_delay_PID=0;
data.fuel_delay_WfP3=0;
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
data.HGC.SAS=1; %使用流体网络法计算空气系统特性
%% 放气系统
data.HPCDeflate.Speed=2.2e4;  %压气机开启放气的动力轴临界转速
data.HPCDeflate.Position=1;   %压气机放气位置
data.HPCDeflate.Ratio=0.0002;      %压气机放气量
data.HPTDeflate.OpenSpeed=6300;  %涡轮开启放气的动力轴临界转速
data.HPTDeflate.CloseSpeed=6300;  %涡轮开启放气的动力轴临界转速
data.HPTDeflate.Ratio=0.00;      %高压涡轮后放气量
data.HPTDeflate.Delay=0;      %高压涡轮后放气延迟时间
data.Deflatemethod=1;           %放气方式1简单模型，2复杂
%% 高压轴
data.HPS.J=14.96;      %转动惯量
%% 低压轴
data.LPS.J=318;      %转动惯量
%% 燃机风阻损失(正数/W)
data.loss=0;
data.Metal_open=0; %是否计算热惯性
%%
basic_setting;
%% 负载
data.Power_d=dp.PW;%设计点燃机输出功率
%% 控制系统-限制值保护
data.LimitOpen=1;
LIMIT.maxFAR_X=[0,9999999];
LIMIT.maxFAR_Y=[8e-7,8e-7];
LIMIT.minFAR_X=[0,9999999];
LIMIT.minFAR_Y=[0.00001e-7,0.00001e-7];

LIMIT.minXdot_HPShaft_X=[0,9999999];
LIMIT.minXdot_HPShaft_Y=[-1200,-1200];
LIMIT.maxXdot_HPShaft_X=HPS_Ndot_up_n1;
LIMIT.maxXdot_HPShaft_Y=HPS_Ndot_up;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
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
%% 仿真时间
data.time=20;
data.deltat=0.05;
%% 负载
data.PT_Shaft=6000;        
data.loadingmethod=3;%4：在loadingDIY中设置负载大小；3：电力负载   
data.Load=loading(0,data);  
time0();                    
%% 热惯性
data.Metal_open=0; %是否计算热惯性
data.Metal.mcp_HPC=200*460;%质量*比热容
data.Metal.mcp_HPT=100*460;%质量*比热容
data.Metal.mcp_LPT=100*460;%质量*比热容
data.Metal.Ah_HPC=100;%面积*对流换热系数
data.Metal.Ah_HPT=100;%
data.Metal.Ah_LPT=100;%
%% 控制系统
data.n2_demand=6000;       %目标动力轴转速
y_demand=data.n2_demand;
data.Kp_out=0.6*24*2.5;
data.Ki_out=0.1*4*20;
data.Kp_in=0.2;
data.Ki_in=0.1;
data.feedforward=0;%前馈控制环节，1开启，0关闭
data.Kp_out_PID=0.5;
data.Ki_out_PID=0.2;
data.Kp_in_PID=0.2;
data.Ki_in_PID=0.1;
data.returnPID_open=80;%恢复到正常时的核心机转速与稳定值转速偏差
data.PI_in=Wf0*3600/0.81/9;
data.PI_out=HP_Shaft0;
data.int_error_in=0;
data.int_error_out=0;
%最低燃油质量流量
data.Fuel_MinM=0.09;
%燃油开环控制
data.OpenControl.Switch=0;%是否使用燃油开环控制，1为使用，0为不使用，提前定义
data.OpenControl.MaxLoadChangeRate=100;%启动升工况的临界负载变化率，提前定义
data.OpenControl.MinLoadChangeRate=-100;%启动降工况的临界负载变化率，提前定义
data.OpenControl.MaxFarTable_X=[0,99999];%启动升工况的临界负载变化率，提前定义
data.OpenControl.MaxFarTable_Y=[5e-7,5e-7];%启动升工况的临界负载变化率，提前定义
data.OpenControl.MinFarTable_X=[0,99999];%启动降工况的临界负载变化率，提前定义
data.OpenControl.MinFarTable_Y=[2.5e-7,2.5e-7];%启动降工况的临界负载变化率，提前定义
data.returnPID_open=80;%恢复到正常时的核心机转速与稳定值转速偏差
data.returnPID=80;
%% 主程序
    aircraft=@engine_DS1;%迭代程序
    aircraft_limit=@engine_DS_NoSAS_LIMITall;%最小选择器程序
    aircraft_limit2=@engine_DS_NoSAS_LIMITall2;%最小选择器程序
    opt.maxiter=50;
    opt.tolfun=1e-6;
    opt.tolx=1e-12;

    bounds=[2 100
        -1 3
        -1 3
        -5 3
        ];
    if data.HGC.SAS,x0(5,1)=1960882.85266362;bounds=[bounds;1e5,5e6];end
    %预处理x 
    i=0;
    maxXdot_HPShaft_all=[];
    minXdot_HPShaft_all=[];
    HPShaft_need=[HP_Shaft0];
    limit_signal=0;
    while 1
        data.CT=data.deltat*i;% 总运行时间
        [~,data]=loading(data.CT,data);%负载
        if(i)
            limitactUI_change2();
            Xdot_HPShaft=WholeEngine1(i+1).Others.Xdot_HPShaft;
            Xdot_PTShaft=WholeEngine1(i+1).Others.Xdot_PTShaft;
            data.HP_Shaft=data.HP_Shaft+data.deltat*Xdot_HPShaft;
            data.PT_Shaft=data.PT_Shaft+data.deltat*Xdot_PTShaft;
            data.Metal.T_HPC=data.Metal.T_HPC+data.deltat*WholeEngine1(i+1).HPCData.dT_matel;
            data.Metal.T_HPT=data.Metal.T_HPT+data.deltat*WholeEngine1(i+1).HPTData.dT_matel;
            data.Metal.T_LPT=data.Metal.T_LPT+data.deltat*WholeEngine1(i+1).PTData.dT_matel;
            fprintf('Completed %s seconds of transition state performance calculation\n',num2str(data.CT,'%f  '));
        else
            data.type=1;
            %求解初始时刻燃机参数
            FUN=@(x) funwrapper(aircraft,x,data);
            [x, ithist]=broyden(FUN,x0,opt,bounds);%
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                fprintf('%s\n','Debug')
            end
            [~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS1(x,data);%这里保存的值不一定是最终值
            WholeEngine1(i+1).Others.HPShaft_need=HPShaft_need(i+1);
            x2=[x;WholeEngine1(end).B_Data.Wf];%
            x_type1=[];
            x_type2=[];
            x_type3=[];
            x_type4=[];
            OpenControlMethod=4;
            Ng_S=0;
            CalMehthod=1;
        end
        %最终时刻判定
        i=i+1;
        CT=data.CT;
        if CT>=data.time
            break
        end
    end

    WholeEngine1(1).Others.maxXdot_HPShaft=WholeEngine1(2).Others.maxXdot_HPShaft;
    WholeEngine1(1).Others.minXdot_HPShaft=WholeEngine1(2).Others.minXdot_HPShaft;
toc
% changetime=data.changetime;
% fprintf('切换到PID控制的时刻为',num2str(changetime,'%f  '),'s');
%% 特性检查
for j=1:length(WholeEngine1)
    Rline_HPC(j)=WholeEngine1(j).HPCData.Rline;
    Rline_HPT(j)=WholeEngine1(j).HPTData.Rline;
    Rline_PT(j)=WholeEngine1(j).PTData.Rline;
end
if any(Rline_HPC>1)||any(Rline_HPC<0)
    fprintf('Warning: The operating point is outside the compressor characteristic map range\n')
end
if any(Rline_HPT>1)||any(Rline_HPT<0)
    fprintf('Warning: Operating point exceeds the high pressure turbine characteristic map range\n')
end
if any(Rline_PT>1)||any(Rline_PT<0)
    fprintf('Warning: The operating point is outside the power turbine characteristic diagram range\n')
end
%% 绘图
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%绘图参考
TIME.deltat=data.deltat;
TIME.num=i;
TIME.time=0:data.deltat:((i-1)*TIME.deltat);
time=0:data.deltat:(length(WholeEngine1)-1)*data.deltat;%时间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for j=1:i
    PT_Shaft_all(j)=WholeEngine1(j).PT_Shaft;
end
figure
plot(time(1:length(PT_Shaft_all)),PT_Shaft_all,'LineWidth',1.2)
ylabel('低压轴转速/rpm')
xlabel('时间/s')
set(gca,'FontSize',12);
grid on
% save('dele','PT_Shaft_all')

for j=1:i
    HP_Shaft_all(j)=WholeEngine1(j).HP_Shaft;
end
figure
plot(time(1:length(PT_Shaft_all)),HP_Shaft_all,'LineWidth',1)
ylabel('高压轴转速')
xlabel('时间/s')%% 需求高压 轴转速
% hold on
% plot(0:data.deltat:(length(HPShaft_need)-1)*data.deltat,HPShaft_need,'LineWidth',1)
% ylabel('需求高压轴转速')
% xlabel('时间/s')

% for j=1:i
%     Xdot_HPShaft_all(j)=WholeEngine1(j).Others.Xdot_HPShaft;
% end
% figure
% plot(0:data.deltat:(length(Xdot_HPShaft_all)-1)*data.deltat,Xdot_HPShaft_all,'k-','LineWidth',1.2)
% hold on
% plot(0:data.deltat:(length(maxXdot_HPShaft_all)-1)*data.deltat,maxXdot_HPShaft_all,'r--','LineWidth',1.2)
% plot(0:data.deltat:(length(minXdot_HPShaft_all)-1)*data.deltat,minXdot_HPShaft_all,'b--','LineWidth',1.2)
% legend('实际升/降转速率','临界升转速率','临界降转速率')
% xlabel('时间/s')
% ylabel('核心机升/降转速率/(rpm/s)')
% set(gca,'FontSize',12);
% grid on

%% 例1：查看压气机喘振裕度
%将WholeEngine1内的喘振裕度提取到SM中
for j=1:length(WholeEngine1)
    far(j)=WholeEngine1(j).B_Data.Wf/GasPth1(j).GasOut_HPC.Pt;
end
%绘图
figure
plot(0:data.deltat:(length(far)-1)*data.deltat,far,'LineWidth',1.2)%data.deltat为时间步长，等于TIME.deltat
ylabel('油气比')
xlabel('时间/s')
grid on
%% T45
%将WholeEngine1内的喘振裕度提取到SM中
for j=1:length(WholeEngine1)
    T45(j)=GasPth1(j).GasOut_HPT.Tt;
end
%绘图
figure
plot(0:data.deltat:(length(T45)-1)*data.deltat,T45,'LineWidth',1.2)%data.deltat为时间步长，等于TIME.deltat
ylabel('T45')
xlabel('时间/s')
grid on
%% 查看电力负载
if data.loadingmethod==3
    Generator_load_all=[];
    GT_power=[];
    for j=1:length(WholeEngine1)
        Generator_load_all(j)=WholeEngine1(j).Others.Load;
        GT_power(j)=WholeEngine1(j).PTData.Pwrout;
    end
    %绘图
    figure
    hold on
    plot(0:data.deltat:(length(T45)-1)*data.deltat,Generator_load_all,'LineWidth',1.2)%电机负载功率
    plot(0:data.deltat:(length(T45)-1)*data.deltat,GT_power,'LineWidth',1.2)%燃机功率
    ylabel('功率/w')
    xlabel('时间/s')
    legend('电力负载功率','燃机功率')
    grid on

    figure
    plot(0:data.deltat:(length(T45)-1)*data.deltat,data.Generator.Uoutput,'LineWidth',1.2)%电压
    ylabel('点击输出端电压')
    xlabel('时间/s')
    grid on

end