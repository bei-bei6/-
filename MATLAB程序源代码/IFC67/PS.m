function [X, T, V, H] = PS(P, S)
%***************************************
% 已知压力比熵求性质函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
%              V      比容   m^3/kg 
%              H      比焓   kJ/kg
%              S      比熵   kJ/(kg.℃ )
%              x      干度　　<1(过热度℃）
% ****作者：王雷 zrqwl2003@126.com*****************
%***************************************
TS = TSK(P);
[VG, HG, SG]=PTG(P, TS);
[VF, HF, SF]=PTF(P, TS);
if (S < SF) %THen GoTo 10
    X = 0;
    T = 89.85 * S;
    while(1)
       [V, H, SB]=PTF(P,T);
        X = T - TS;
        if (abs(S - SB) <= 0.0000005)
            break;
        end
        T = T + 89.85 * (S - SB);
    end
else
    if (S <= SG) %THen GoTo 20
        X = (S - SF) / (SG - SF);
        T = TS;
        V = VF + X * (VG - VF);
        H = HF + X * (HG - HF);
    else    
        X = 1;
        n = 1;
        ZP = P / 980.7;
        ZS = 0.23888846 * S;
        while(1)
            ZT = (ZS - 1.44) * 1.1594 * log(10) + 0.25381 * 1.1594 * log(ZP);
            ZT = exp(ZT);
            T = 1000 * ZT - 273.15;
            if (T < TS) %THen GoTo 30
                T = TS;
                SB = SG;
                V = VG;
                H = HG;
                ZT = (273.15 + T) / 1000;
                ZSB = (log(ZT) / 1.1594 - 0.25381 * log(ZP)) / log(10) + 1.44;            
            else
                [V, H, SB]=PTG(P,T);
                ZSB = ZS;
            end
            X = T - TS;
            if (X >= 1)% THen GoTo 50
            else
                X = X + 1;
            end
            if (abs(S - SB) <= 0.00000005)% THen GoTo 1000
                break;
            end
            if (n <= 1) %THen GoTo 60
                ZS = ZSB + 0.1672 * (S - SB);
            else
                ZS = ZSB + (S - SB) * (ZSB - ZSA) / (SB - SA);               
            end
            n = n + 1;
            SA = SB;
            ZSA = ZSB;
        end
    end
end
