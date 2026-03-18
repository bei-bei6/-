function [Effector_Damand,int_error_in]=PID(Input_dmd,Input_sensed,data)
global PI_in
Kp =0.04;
Ki=0;
% Kd=0;
% de_old=Input_dmd-data.PT_Shaft_old;%上一时刻的偏差
% de_new=Input_dmd-Input_sensed;
%Effector_Damand=(Input_dmd-Input_sensed)*Kp+PI_IC_M+(Input_dmd-Input_sensed)*Ki*data.deltat+Kd*(de_new-de_old)/data.deltat;%pid
% Effector_Damand=(Input_dmd-Input_sensed)*Kp+PI_in+(Input_dmd-Input_sensed)*Ki*data.deltat;%pi
int_error_in=data.int_error_in+(Input_dmd-Input_sensed)*data.deltat;
Effector_Damand=(Input_dmd-Input_sensed)*Kp+int_error_in*Ki+PI_in;%pi
%油气比限制
if Effector_Damand<0
    Effector_Damand=0;%0.00731779614201304;
elseif Effector_Damand>10
    Effector_Damand=10;
end

% PI_in=PI_in+(Input_dmd-Input_sensed)*Ki*data.deltat;
end


