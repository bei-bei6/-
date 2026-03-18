function [T,V,H,S] = PX(P,X)
%***************************************
% 已知压力干度求性质函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
%              V      比容   m^3/kg 
%              H      比焓   kJ/kg
%              S      比熵   kJ/(kg.℃ )
%              x      干度   　<1(过热度℃）
% ****作者：王雷 zrqwl2003@126.com**********  
%***************************************
T = TSK(P);
[VG, HG, SG]=PTG(P, T);
[VF, HF, SF]=PTF(P, T);
V = VF + X * (VG - VF);
H = HF + X * (HG - HF);
S = SF + X * (SG - SF);