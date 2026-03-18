% 燃烧室x求解程序
function x= CAL_x(Pmax,Pmean,Tt,A,W)
    [gamma,~]=tfd2gammarRg(Tt,0,0);
    [Mn,Pb]=static_parameter(Pmean,Tt,W,A);%平均马赫数

%     T_s=Tt*(Pmean/Pb)^(-(gamma-1)/gamma);%静温
    Mn_max=sqrt(2/(gamma-1)*((Pmax/Pb)^((gamma-1)/gamma)-1));
    x=(Mn_max-Mn)/Mn;
end

