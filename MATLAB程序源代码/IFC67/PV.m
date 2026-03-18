function [X, T, S, H] = PV(P, V)
%***************************************
% 已知压力比熵求性质函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
%              V      比容   m^3/kg 
%              H      比焓   kJ/kg
%              S      比熵   kJ/(kg.℃ )
%              x      干度　　<1(过热度℃）
% ****作者：王雷 zrqwl2003@126.com********  
%***************************************
TS = TSK(P);
[VG, HG, SG]=PTG(P, TS);
[VF, HF, SF]=PTF(P, TS);
if (V > VG) 
    X = 0;
    T = TS;
    while(1)
       [VB, H, S]=PTG(P,T);
        X = T - TS;
        if (abs(V - VB) <= 0.0000005)
            break;
        end
        T = T + 0.1;
    end
else
    if  (V > VF)      
        X = (V - VF) / (VG - VF); 
        T = TS;
        S = SF + X * (SG - SF);
        H = HF + X * (HG - HF);
    else
        X = 0;
        T = TS;
        while(1)
           [VB, H, S]=PTF(P,T);
           X = T - TS;
            if (abs(V - VB) <= 0.00000005)
                break;
            end
            T = T - 0.1;
        end
    end
end
