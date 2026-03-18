function T = TSK(P)
%***************************************
% 某下压力饱和温度函数
%  Parameters: P      压力   MPa 
%              t      温度   ℃ 
% ****作者：王雷 zrqwl2003@126.com*******
%***************************************
TA = 100 * P ^ 0.25;
k=1;
while(k==1)
    PB = PSK(TA);
    if(abs((P - PB) / P) < 0.0000001)
        T = TA;
        k=0;
        break;
    else
        TA = TA + 25 * (P - PB) / PB ^ 0.75;
    end
end 