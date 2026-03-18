function [X,V,H,S] = PT(P,T)
%***************************************
% 已知压力温度求性质函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
%              V      比容   m^3/kg 
%              H      比焓   kJ/kg
%              S      比熵   kJ/(kg.℃ )
%              x      干度  　<1(过热度℃）
% ****作者：王雷 zrqwl2003@126.com*****************  
%***************************************
        TS = TSK(P);
        X = T - TS;
        if (X < 0)
              [V,H,S]=PTF(P, T);
        end
        if (X == 0)
              [V,H,S]=PTF(P, T);
        end  
        if (X > 0)
              [V,H,S]=PTG(P, T);
        end
        X = X + 1;
