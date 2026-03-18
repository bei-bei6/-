%%
%% 基准参数
    data.Cons=Cons_set();   %设置常用参数值
    data.PR_inlet_d=dp.PR_inlet_d;      %总压恢复系数
    data.W_inlet_d=dp.Wc_inlet_d;  %设计点进气道换算流量
    data.Combustor.type=1;
    data.Combustor.Eff=dp.Combustor_Eff;   %燃烧效率，若存在定义则按照恒定值处理，若为[]则按照公式处理
    data.Combustor.omiga_d=dp.omiga; 
    data.Combustor.b=1.6;
    data.Combustor.PR=dp.Combustor_PR;    %燃烧室总压恢复系数，若存在定义则按照损失正比于换算流量处理，若为[]则按照公式处理   
    data.Wc_Combustor_d=dp.Wc_Combustor_d;   
    data.Combustor.LHV=dp.heatvalue;    %燃料低位热值/J
    data.Wf=[];%%无意义，用于兼容稳态和过渡态程序
    data.PR_volute_d=dp.PR_volute_d;      %设计点排气系统压力损失/Pa，Ps8/P0
    data.W_volute_d=dp.Wc_volute_d;       %设计点排气系统换算流量
    data.Area=dp.Area;%排气蜗壳出口面积
    data.HPS.Eff=dp.HPS_Eff;     %机械效率
    data.beforePT_PR=dp.beforePT_PR;
    data.beforePT_Wc=dp.beforePT_Wc;%设计点换算流量
    data.afterPT_PR=dp.afterPT_PR;
    data.afterPT_Wc=dp.afterPT_Wc;%设计点换算流量
    data.shaftlossmethod=dp.shaftlossmethod;%机械损失计算方法，1为恒定机械效率
    data.bearingscale_on=dp.bearingscale_on;%匹配开启
    data.bearing1=dp.bearing1;%轴承参数
    data.bearingscale_num1=dp.bearingscale_num1;%缩放系数
    data.LPS.Eff=dp.LPS_Eff;     %机械效率
    data.bearing2=dp.bearing2;
    data.bearingscale_num2=dp.bearingscale_num2;