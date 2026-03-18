function [F,GasPth,WholeEngine]=engine_DS_NoSAS_LIMITall(x,data)
%四个限制量：最大升转速率，最小升转速率，最大油气比，最小油气比
%%
W=x(1);%实际入口流量？
HPC_Rline =x(2);%HPC beta
HPT_Rline =x(3);%HPT beta
PT_Rline =x(4);%PT beta
data.Wf=x(5);%燃油流量

HP_Shaft=data.HP_Shaft;
PT_Shaft=data.PT_Shaft;
HPTvalve=data.HPTvalve;%涡轮放气指令
%%
[GasOut_Inlet,Inlet_Data]=Inlet(W,data);%进气道
[GasOut_HPC,CoolFlow,HPC_NErr,HPC_TrqOut,HPC_Data]=HPC(GasOut_Inlet,HPC_Rline,HP_Shaft,data);%HPC
if data.type==5
    FAR_Burner=data.WfP3*GasOut_HPC.Pt*divby(GasOut_HPC.W);
else
    FAR_Burner=data.Wf*divby(GasOut_HPC.W);
end
[GasOut_Burner,B_Data]=Burner(GasOut_HPC,FAR_Burner,data);%燃烧室
[GasOut_HPT,HPT_NErr,TrqOut_HPT,HPT_Data]=HPT(CoolFlow,GasOut_Burner,HPT_Rline,HPC_Data.Nmech,data);%高压涡轮
% 放气
if HPTvalve==1
    if data.Deflatemethod==2
        data.HPTDeflate.Ratio=data.HPTDeflate_Win/GasOut_HPT.W;%放气比，放气阀进口流量/主流流量
        BypassOut=data.HPTDeflate_GasOut;%放气出口参数
        [~,MFPOut]=Splitter(GasOut_HPT,data.HPTDeflate.Ratio);%放气后的主流参数
    else
        [BypassOut,MFPOut]=Splitter(GasOut_HPT,data.HPTDeflate.Ratio);%7-10%
    end
else
    MFPOut=GasOut_HPT;
    BypassOut.W=0;
end
[GasOut_HPT1,Duct_before_PTdate]=Duct_before_PT(MFPOut,data);
[GasOut_PT,PT_NErr,TrqOut_PT,PT_Data]=LPT(CoolFlow,GasOut_HPT1,PT_Rline,PT_Shaft,data);%动力涡轮
[GasOut_PT1,Duct_after_PTdate]=Duct_after_PT(GasOut_PT,data);
Load=data.Load;%负载
if HPTvalve==1
    GasOut_PT2=Mix(GasOut_PT1,BypassOut);
else
    GasOut_PT2=GasOut_PT1;
end
[Core_NErr,WOut_Core]=volute(GasOut_PT2,data.P0,data);%蜗壳

[HP_Shaft,HP_Ndot]=HPS(HPC_TrqOut,TrqOut_HPT,HPC_Data.Nmech,data);
[PT_Shaft,PT_Ndot]=PTS(Load/PT_Data.Nmech,TrqOut_PT,PT_Data.Nmech,data);
%% 构造第五个残差方程
switch data.type
    case 1
        NErr=(HP_Ndot-data.maxXdot_HPShaft)*divby(data.maxXdot_HPShaft);
    case 2
        NErr=(HP_Ndot-data.minXdot_HPShaft)*divby(data.minXdot_HPShaft);
    case 3 
        WfP3=B_Data.Wf/GasOut_HPC.Pt;
        NErr=(WfP3-data.maxWfP3)*divby(data.maxWfP3);        
    case 4        
        WfP3=B_Data.Wf/GasOut_HPC.Pt;
        NErr=(WfP3-data.minWfP3)*divby(data.minWfP3);
end       
        
F=[HPC_NErr;HPT_NErr;PT_NErr;Core_NErr;NErr];
fprintf('NErr=[%s]\n',num2str(F','%f  '));
%%
GasPth.GasOut_Inlet=GasOut_Inlet;
GasPth.GasOut_HPC=GasOut_HPC;
GasPth.GasOut_Burner=GasOut_Burner;
GasPth.GasOut_HPT=GasOut_HPT;
GasPth.GasOut_PT=GasOut_PT;
GasPth.Volute=WOut_Core;

GasPth.DeflateDuct.Pt=GasPth.GasOut_PT.Pt;%这两个参数用于valve中放气阀初始状态计算
GasPth.DeflateDuct.Tt=GasPth.GasOut_PT.Tt;%这两个参数用于valve中放气阀初始状态计算
GasPth.DeflateDuct.W=BypassOut.W;
GasPth.DeflateDuct.ValveOpening=0;
%
WholeEngine.Inlet_Data=Inlet_Data;
WholeEngine.HPCData=HPC_Data;
WholeEngine.B_Data=B_Data;
WholeEngine.HPTData=HPT_Data;
WholeEngine.PTData=PT_Data;
WholeEngine.HP_Shaft=HP_Shaft;
WholeEngine.HP_Shaftcor=HP_Shaft/sqrt(data.T0/288.15);
WholeEngine.PT_Shaft=PT_Shaft;
WholeEngine.before_PT=Duct_before_PTdate;
WholeEngine.after_PT=Duct_after_PTdate;
WholeEngine.Deflate.HPTvalve=HPTvalve;
WholeEngine.Others.Xdot_HPShaft=HP_Ndot;
WholeEngine.Others.Xdot_PTShaft=PT_Ndot;
WholeEngine.Others.Load=-Load;
%
assignin('base','Xdot_HPShaft',HP_Ndot);
assignin('base','Xdot_PTShaft',PT_Ndot);
end


