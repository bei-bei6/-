function Ploss=Powerloss_cal(N,bearing,data,shafttype)
    u=interp1g(bearing.u_x,bearing.u_y,N);
    Q1=interp1g(bearing.Q1_x,bearing.Q1_y,N);
    Q2=interp1g(bearing.Q2_x,bearing.Q2_y,N);
    Q3=interp1g(bearing.Q3_x,bearing.Q3_y,N);

    Powerloss1=Bearcal(N,bearing.D1,u,Q1,bearing.type1);
    Powerloss2=Bearcal(N,bearing.D2,u,Q2,bearing.type2);
    Powerloss3=Bearcal(N,bearing.D3,u,Q3,bearing.type3);
    Powerloss4=interp1g(bearing.powerextract_x,bearing.powerextract_y,N);
    Ploss=Powerloss1+Powerloss2+Powerloss3+Powerloss4;
    if data.bearingscale_on
        if shafttype==1
            Ploss=Ploss*data.bearingscale_num1;
        else
            Ploss=Ploss*data.bearingscale_num2;
        end
    end  
end
