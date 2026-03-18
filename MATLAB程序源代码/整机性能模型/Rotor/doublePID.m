function [Wf,int_error_in,int_error_out,n1_dmd,interror_in_old,interror_out_old]=doublePID(n2_dmd,n1,n2,data)
interror_in_old=data.int_error_in;
interror_out_old=data.int_error_out;
%外环
% global PI_out
PI_out=data.PI_out;
Kp_out=data.Kp_out;
Ki_out=data.Ki_out;
int_error_out=data.int_error_out+(n2_dmd-n2)*data.deltat;
n1_dmd=PI_out+(n2_dmd-n2)*Kp_out+int_error_out*Ki_out;
%内环
% global PI_in
PI_in=data.PI_in;
Kp_in=data.Kp_in;
Ki_in=data.Ki_in;
int_error_in=data.int_error_in+(n1_dmd-n1)*data.deltat;
Wf_Lh=(n1_dmd-n1)*Kp_in+PI_in+int_error_in*Ki_in;%L/h

Wf=Wf_Lh*0.81/3600;%kg/s
Wf=Wf*9;%增益，注意这几个值修改之后要改PI_in

%最小燃油流量的限制
if Wf<0.0001
    Wf=0.0001;
    int_error_out=interror_out_old;
    int_error_in=interror_in_old;
elseif Wf>50
    Wf=50;
    int_error_out=interror_out_old;
    int_error_in=interror_in_old;
end
end