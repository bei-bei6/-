function [NOut,Ndot]=PTS(load,TrqOut_PT,NIn,data)
Shaft_Inertia_M=data.LPS.J;%1.25;%转动惯量
if data.shaftlossmethod==1
    Torque=load+TrqOut_PT;%静扭矩，注意轴效率在LPT内考虑了
else
    Ploss=Powerloss_cal(NIn,data.bearing2,data,2);
    Torque=(load*NIn+TrqOut_PT*NIn/data.LPS.Eff-Ploss)/NIn;
end  
Torque=Torque*30/pi;
Ndot=Torque*60/(2*pi*Shaft_Inertia_M);%加速度
NOut=NIn;%转速，不改变
end



% Shaft_Inertia_M=data.LPS.J;%1.25;%转动惯量
% Torque=load+TrqOut_PT;%静扭矩，注意轴效率在LPT内考虑了
% Torque=Torque*30/pi;
% Ndot=Torque*60/(2*pi*Shaft_Inertia_M);%加速度
% NOut=NIn;%转速，不改变