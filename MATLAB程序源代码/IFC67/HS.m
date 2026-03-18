function [X, P,T, V] = HS(H, S)
%************************************************
% 已知比焓、比熵求过热蒸汽、饱和蒸汽、湿蒸汽性质函数
%  Parameters: P      压力 MPa 
%              T      温度  
%              V      比容  
%              H      焓  
%              S      熵  
%              X      干度(过热度)
% ****作者：王雷 zrqwl2003@126.com*****************
% ************************************************
G=[-32230.913,16763.0198,-2684.70102,126.015382,6.08691173,-0.515969833];
w=[0.08275963, -1.2121626, -73.61409,6.6074894,-0.4065599];
HG = 0;
for i = 1 :1: 6
    HG = HG + G(i) * S ^ (i - 1);
end
if (H > HG) 
    X = 1;
    ZH = H / 4186.8;
    ZS = 0.238846 * S;
    n = 1;
    while(1)
        ZT = (sqrt(0.035081 + 0.085 * (ZH - 0.4949)) - 0.1873) / 0.085;
        ZP = exp(13.064 - 9.072 * ZS + 3.3982 * log(ZT));
        T = 1000 * ZT - 273.15;
        P = 98.0665 * ZP;
        TS = TSK(P);
        if (T >= TS) 
            ZHB = ZH;
            ZSB = ZS;
        else
            T = TS;
            ZT = (T + 273.15) / 1000;
            ZHB = ((0.085 * ZT + 0.1873) ^ 2 - 0.035081) / 0.085 + 0.4949;
            ZSB = (13.064 - log(ZP) + 3.3982 * log(ZT)) / 9.072;
        end
        X = T - TS;
        if (X >= 1)
        else
            X = X + 1;
        end
        [V, HB, SB]=PTG(P, T );
        if ((abs(H - HB) < 0.0005) && (abs(S - SB) < 0.000001))
            break;
        end
        if (n > 1)
            ZH = ZHB + (H - HB) * (ZHB - ZHA) / (HB - HA);
            ZS = ZSB + (S - SB) * (ZSB - ZSA) / (SB - SA) ;
        else
            ZH = ZHB + 0.0002388 * (H - HB);
            ZS = ZSB + 0.2388 * (S - SB);
        end
        n = n + 1;
        HA = HB;
        SA = SB;
        ZHA = ZHB;
        ZSA = ZSB;
        ZHB = ZH;
        ZSB = ZS;
    end
else
    TB = H / S;
    while(1)
        GF = 0;
        for i = 1 :1: 5
            GF = GF + w(i) * (TB * 0.01) ^ (i - 1);
        end
        T = (H - GF) / S - 273.15;
        if (abs(T - TB) < 0.001)
            break;
        end
        TB = T;
    end
    P = PSK(T);
    [VG, HG, SG]=PTG(P,T);
    [VF, HF, SF]=PTF(P,T);
    X = (H - HF) / (HG - HF);
    V = VF + X * (VG - VF);
end
