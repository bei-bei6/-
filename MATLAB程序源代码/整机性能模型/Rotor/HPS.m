function [NOut,Ndot]=HPS(HPC_TrqOut,TrqOut_HPT,NIn,data)
Shaft_Inertia_M=data.HPS.J;
if data.shaftlossmethod==1
    Torque=HPC_TrqOut+TrqOut_HPT*data.HPS.Eff;
else
    Ploss=Powerloss_cal(NIn,data.bearing1,data,1);
    Torque=(HPC_TrqOut*NIn+TrqOut_HPT*NIn-Ploss)/NIn;
end  
Torque=Torque*30/pi;%
Ndot=Torque*60/(2*pi*Shaft_Inertia_M);
NOut=NIn;
end

