function [F,GasPth,WholeEngine]=engine_SS_offdesign(x,data)
% fprintf('x=[%s]\n',num2str(x','%f  '));
W=x(1);%实际入口流量？
HPC_Rline =x(2);%HPC beta
FAR_Burner=x(3);%油气比
HPT_Rline =x(4);%HPT beta
PT_Rline =x(5);%PT beta
HP_Shaft=data.HP_Shaft;%高压轴物理转速？

PT_Shaft=data.PT_Shaft;
% load=data.load-data.loss;
%%
GasOut_Inlet=Inlet(W,data);%进气道
[GasOut_HPC,CoolFlow,HPC_NErr,HPC_TrqOut,HPC_Data]=HPC(GasOut_Inlet,HPC_Rline,HP_Shaft,data);%HPC
%引气量计算
if data.HGC.SAS==1
    Pb_1=x(6);%
    Data.HP_Shaft=HP_Shaft;
%     Data.LP_Shaft=PT_Shaft;
    %
    WW1=ws_branch1_czb(CoolFlow.HPT_stator.Pt,CoolFlow.HPT_stator.Tt,Pb_1,HP_Shaft);

    WW1_0=CoolFlow.HPT_stator.W;%修正前的引气流量
    CoolFlow.HPT_stator.W=WW1;%修正后引气流量
    HPC_Data.CoolFlow.HPT_stator.W=WW1;
    GasOut_HPC.W=GasOut_HPC.W+WW1_0-WW1;%压气机出口流量修正
end
[GasOut_Burner,B_Data]=Burner(GasOut_HPC,FAR_Burner,data);%燃烧室
[GasOut_HPT,HPT_NErr,TrqOut_HPT,HPT_Data]=HPT(CoolFlow,GasOut_Burner,HPT_Rline,HPC_Data.Nmech,data);%高压涡轮
[GasOut_HPT2,Duct_before_PTdate]=Duct_before_PT(GasOut_HPT,data);
[GasOut_PT,PT_NErr,TrqOut_PT,PT_Data]=LPT(CoolFlow,GasOut_HPT2,PT_Rline,PT_Shaft,data);%动力涡轮
[GasOut_PT2,Duct_after_PTdate]=Duct_after_PT(GasOut_PT,data);
[Core_NErr,Volute]=volute(GasOut_PT2,data.P0,data);%蜗壳
[HP_Shaft,HP_Ndot]=HPS(HPC_TrqOut,TrqOut_HPT,HPC_Data.Nmech,data);
%% 更新燃烧室进口参数
if data.HGC.SAS==1
    P41_NErr= (Pb_1 - HPT_Data.P41*0.9)*divby(HPT_Data.P41*0.9);
    F=[HPC_NErr;HPT_NErr;PT_NErr;Core_NErr;HP_Ndot;P41_NErr];
else
    F=[HPC_NErr;HPT_NErr;PT_NErr;Core_NErr;HP_Ndot];
end
% fprintf('NErr=[%s]\n',num2str(F','%f  '));
%%
% GasPth.GasOut_Ambient=GasOut_Ambient;
GasPth.GasOut_Inlet=GasOut_Inlet;
GasPth.GasOut_HPC=GasOut_HPC;
GasPth.GasOut_Burner=GasOut_Burner;
GasPth.GasOut_HPT=GasOut_HPT;
GasPth.GasOut_PT=GasOut_PT;
GasPth.Volute=Volute;
%
% WholeEngine.Ambient=Data_Ambient;
WholeEngine.Inlet=GasOut_Inlet;
WholeEngine.HPCData=HPC_Data;
WholeEngine.B_Data=B_Data;
WholeEngine.HPTData=HPT_Data;
WholeEngine.PTData=PT_Data;
WholeEngine.HP_Shaft=HP_Shaft;
WholeEngine.PT_Shaft=PT_Shaft;
WholeEngine.before_PT=Duct_before_PTdate;
WholeEngine.after_PT=Duct_after_PTdate;
% WholeEngine.Fg=Fg;
% WholeEngine.load=load;

assignin('base','HPShaft',HP_Shaft);
assignin('base','Xdot_HPShaft',HP_Ndot);
assignin('base','PT_POWER',PT_Data.Pwrout);
%
end