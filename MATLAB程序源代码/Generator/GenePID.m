function [Vf,int_error]=GenePID(V_dmd,Vreal,data)
%电机励磁系统控制器
    Gene_PI_in=data.Gene_PI_in;
    Kp=data.Generator.Kp;
    Ki=data.Generator.Ki;
    int_error=data.Gene_int_error+(V_dmd-Vreal)*data.Gene_deltat;
    Vf=(V_dmd-Vreal)*Kp+Gene_PI_in+int_error*Ki;
    if Vf<0.001
        Vf=0.001;
    end
    if Vf>25
        Vf=25;
    end
%     Vf=Gene_PI_in;
end