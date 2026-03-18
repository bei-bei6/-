function [X, T, V, S] = PH(P, H)
%***************************************
% 已知压力比焓求性质函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
%              V      比容   m^3/kg 
%              H      比焓   kJ/kg
%              S      比熵   kJ/(kg.℃ )
%              x      干度  　<1(过热度℃）
%****作者：王雷 zrqwl2003@126.com*****************  
%***************************************
TS = TSK(P);
HA=H;
[VG, HG, SG]=PTG(P, TS);
[VF, HF, SF]=PTF(P, TS);
 if (H >= HF) 
     if (H > HG)
        x = 1;
        n = 1;
        ZH = H / 4186.8;
        while(1)
            ZT = (sqrt(0.035081 + 0.085 * (ZH - 0.4949)) - 0.1873) / 0.085;
            T = 1000 * ZT - 273.15;
            if (T < TS)
                T = TS;
                HB = HG;
                V = VG;
                S = SG;
                ZT = (273.15 + TS) / 1000; 
                ZHB=0.08218+(0.085*ZT+0.1873)^2/0.085;
            else
                [V, HB, S]= PTG(P, T);
                ZHB = ZH;           
            end
            X = T - TS;
            if (X >= 1)
            else
                X = X + 1;
            end

            if (abs(H - HB) < 0.001)
                break;
            end
            if(n > 1)
                ZH = ZHB + (H - HB) * (ZHB - ZHA) / (HB - HA);
            else
                ZH = 0.000238 * (H - HB) + ZHB;
            end
            n = n + 1;
            HA = HB;
            ZHA = ZHB;
            ZHB = ZH;
        end
     else
        T = TS;
        X = (H - HF) / (HG - HF);
        V = VF + X * (VG - VF);
        S = SF + X * (SG - SF);
     end
 else
    X = 0;
    T = 0.2195 * HA;
    while(1)
        [V, HB, S]= PTF(P, T);
        X = T - TS;
        if (abs(H - HB) < 0.001)
            break;
        end
        T = T + 0.238846 * (H - HB);
    end
 end