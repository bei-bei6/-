%用于求解迭代初值x0的插值表x0_sheet
data.scale=scale;data.HPCdate=HPCdate;data.HPTdate=HPTdate;data.PTdate=PTdate;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 基本参数
    data.T0=inlet.T;         %入口总温/K
    data.P0=Amb.P;         %入口总压/Pa
    data.PT_Shaft=LPS.speed;     %目标动力轴转速
    data.RH=0;              %相对湿度/[0,1]    
    %% 基准参数
    data.Cons=Cons_set();   %设置常用参数值
    %% 进气道
    data.PR_inlet_d=dp.PR_inlet_d;      %总压恢复系数
    data.W_inlet_d=dp.Wc_inlet_d;  %设计点进气道换算流量
    data.P_loss_inlet=0;
    %% 高压压气机
    %% 燃烧室
    data.Combustor.type=1;
    data.Combustor.Eff=dp.Combustor_Eff;   %燃烧效率，若存在定义则按照恒定值处理，若为[]则按照公式处理
    data.Combustor.omiga_d=dp.omiga; 
    data.Combustor.b=1.6;
   
    data.Combustor.PR=dp.Combustor_PR;    %燃烧室总压恢复系数，若存在定义则按照损失正比于换算流量处理，若为[]则按照公式处理   
    data.Wc_Combustor_d=dp.Wc_Combustor_d; 
    data.Combustor.LHV=dp.heatvalue;    %燃料低位热值/J
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
    %% 动力涡轮
    %% 空气系统
    data.HGC.SAS=0; %使用流体网络法计算空气系统特性
    %% 排气系统
    data.PR_volute_d=dp.PR_volute_d;      %设计点排气系统压力损失/Pa，Ps8/P0
    data.W_volute_d=dp.Wc_volute_d;       %设计点排气系统换算流量
    data.Area=dp.Area;%排气蜗壳出口面积
    data.P_loss_volute=0;
    data.HPTDeflate.Ratio=0;      %高压涡轮后放气量
    %% 管道流动损失总压恢复系数
    data.beforePT_PR=dp.beforePT_PR;
    data.beforePT_Wc=dp.beforePT_Wc;%设计点换算流量
    data.afterPT_PR=dp.afterPT_PR;
    data.afterPT_Wc=dp.afterPT_Wc;%设计点换算流量
    %% 高压轴
    data.shaftlossmethod=dp.shaftlossmethod;%机械损失计算方法，1为恒定机械效率
    data.bearingscale_on=dp.bearingscale_on;%匹配开启
    data.bearing1=dp.bearing1;%轴承参数
    data.bearingscale_num1=dp.bearingscale_num1;%缩放系数
    data.HPS.Eff=dp.HPS_Eff;     %机械效率
    data.HPS.J=14.96;      %转动惯量,数值不影响稳态计算结果
    %% 低压轴
    data.bearing2=dp.bearing2;
    data.bearingscale_num2=dp.bearingscale_num2;
    data.LPS.Eff=dp.LPS_Eff;     %机械效率
    data.LPS.J=318;      %转动惯量,数值不影响稳态计算结果
    %% 燃机风阻损失(正数/W)
    data.loss=0;
    data.Metal_open=0;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
data.Correction.HPC.Nc=[0.6,1];
data.Correction.HPC.W=[1,1];
data.Correction.HPC.Eff=[1,1];
data.Correction.HPC.PR=[1,1];

data.Correction.HPT.Nc=[0.6,1];
data.Correction.HPT.W=[1,1];
data.Correction.HPT.Eff=[1,1];
data.Correction.HPT.PR=[1,1];

data.Correction.LPT.Nc=[1,1.2];
data.Correction.LPT.W=[1,1];
data.Correction.LPT.Eff=[1,1];
data.Correction.LPT.PR=[1,1];
%% 整机子程序
% x0_sheet(:,1)=x0;
i=0;
for Load=-LPT.Power*(1:-0.2:0.2)
    i=i+1;    
    data.Load=Load;%输出功率
    aircraft=@engine_SS;
    FUN=@(x) funwrapper(aircraft,x,data);
    opt.maxiter=1000;%最大迭代次数
    opt.tolfun=1e-7;%收敛容差
    opt.tolx=1e-12;%最小变化量
    bounds=[10 200
        -0.3 1.1
        0 0.3
        -0.3 1.1
        -0.3 1.1
        0 20000
        ];

    [x, ithist]=broyden(FUN,x0,opt,bounds);%,bounds
    [~,GasPth(i),WholeEngine(i)]=engine_SS(x,data);
    x0=x;
    x0_sheet(:,i)=[x0;WholeEngine(i).HPTData.P41*0.9];
    fprintf('%s%0.2f%s\n','Power output is ',WholeEngine(i).PTData.Pwrout/1000,'kW')
end
%%
i=1;
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
fprintf('--------------------------------------------------------------------------\n')
fprintf('--------------------------------------------------------------------------\n')
fprintf('                       Design point \n\n')
fprintf('               W              T             P\n')
fprintf('Station       kg/s            K              Pa\n')
formatSpec = ' %2.0f         %5.3f        %7.2f       %7.3f   \n';
fprintf(formatSpec,A2')
fprintf('-----------------------------------------------------\n')
fprintf('                Efficiency   Pressure ratio\n')
A3=[WholeEngine(i).HPCData.Eff WholeEngine(i).HPCData.PR;
    WholeEngine(i).B_Data.Eff WholeEngine(i).B_Data.PR;
    WholeEngine(i).HPTData.Eff WholeEngine(i).HPTData.PR;  
    WholeEngine(i).PTData.Eff WholeEngine(i).PTData.PR];

formatSpec =' %5.4f        %5.4f        \n';
fprintf('HPC            ')
fprintf(formatSpec,A3(1,:))
fprintf('Burner         ')
fprintf(formatSpec,A3(2,:))
fprintf('HPT            ')
fprintf(formatSpec,A3(3,:))
fprintf('PT             ')
fprintf(formatSpec,A3(4,:))
fprintf('-----------------------------------------------------\n')
formatSpec =' %8.2f';
fprintf('Power output=')
fprintf(formatSpec,WholeEngine(i).PTData.Pwrout/1000)
fprintf(' kW\n')
formatSpec =' %8.6f';
fprintf('Thermal efficiency=')
fprintf(formatSpec,WholeEngine(i).PTData.Pwrout/(WholeEngine(i).B_Data.heat))
fprintf('\n')
formatSpec =' %7.2f';
fprintf('Ng=')
fprintf(formatSpec,x0_sheet(6,1))
fprintf(' rpm')
fprintf('\n')
formatSpec =' %7.2f';
fprintf('Np=')
fprintf(formatSpec,data.PT_Shaft)
fprintf(' rpm')
fprintf('\n')
