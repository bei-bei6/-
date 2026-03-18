function [F,GasPth,WholeEngine]=engine_DS1(x,data)
W=x(1);%实际入口流量？
HPC_Rline =x(2);%HPC beta
HPT_Rline =x(3);%HPT beta
PT_Rline =x(4);%PT beta

HP_Shaft=data.HP_Shaft;
PT_Shaft=data.PT_Shaft;
% FAR_Burner=data.Wf*divby(GasOut_HPC.W);
HPTvalve=data.HPTvalve;%涡轮放气指令
%%
[GasOut_Inlet,Inlet_Data]=Inlet(W,data);%进气道
[GasOut_HPC,CoolFlow,HPC_NErr,HPC_TrqOut,HPC_Data]=HPC(GasOut_Inlet,HPC_Rline,HP_Shaft,data);%HPC

if data.HGC.SAS==1
    Pb_1=x(5);%
    Data.HP_Shaft=HP_Shaft;
%     Data.LP_Shaft=PT_Shaft;
    %
    WW1=ws_branch1_czb(CoolFlow.HPT_stator.Pt,CoolFlow.HPT_stator.Tt,Pb_1,HP_Shaft);

    WW1_0=CoolFlow.HPT_stator.W;%修正前的引气流量
    CoolFlow.HPT_stator.W=WW1;%修正后引气流量
    HPC_Data.CoolFlow.HPT_stator.W=WW1;
    GasOut_HPC.W=GasOut_HPC.W+WW1_0-WW1;%压气机出口流量修正
end
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

%%
if data.HGC.SAS==1
    P41_NErr= (Pb_1 - HPT_Data.P41*0.9)*divby(HPT_Data.P41*0.9);
    F=[HPC_NErr;HPT_NErr;PT_NErr;Core_NErr;P41_NErr];
else
    F=[HPC_NErr;HPT_NErr;PT_NErr;Core_NErr];
end
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
% % WholeEngine.Others.maxXdot_HPShaft_all=data.maxXdot_HPShaft;
% WholeEngine.Others.minXdot_HPShaft_all=data.minXdot_HPShaft;
%
assignin('base','Xdot_HPShaft',HP_Ndot);
assignin('base','Xdot_PTShaft',PT_Ndot);

end