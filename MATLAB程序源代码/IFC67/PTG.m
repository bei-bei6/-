function [V,H,S] = PTG(P,T)
%***************************************
% 已知压力温度求饱和汽、过热蒸汽的性质函数
%  Parameters: p      压力   MPa 
%              t      温度   ℃ 
%              vsteam      比容   m^3/kg 
%              hsteam      比焓   kJ/kg
%              ssteam      比熵   kJ/(kg.℃ )
% ****作者：王雷 zrqwl2003@126.com************
%***************************************
l0 = 15.74373327;l1 = -34.17061978;l2 = 19.31380707;
B = 0.7633333333; b1 = 16.83599274; c1 = 4.260321148;
buv=[0.06670375918, 1.388983801,0;0.08390104328,0.02614670893,-0.03373439453;0.4520918904,0.1069036614,0;-0.5975336707, -0.08847535804,0;0.5958051609,-0.5159303373,0.2075021122;0.1190610271,-0.09867174132,0;0.1683998803,-0.05809438001,0;0.006552390126,0.0005710218649,0];
zuv=[13,3,0;18,2,1;18,10,0;25,14,0;32,28,24;12,11,0;24,18,0;24,14,0];
b0=[28.56067796,-54.38923329,0.4330662834,-0.6547711697,0.08565182058];
b9=[193.6587558,-1388.522425,4126.607219,-6508.211677,5745.984054,-2693.088365, 523.5718623];
xul=[14,0,0;19,0,0;54,27,0];        
bul=[ 0.4006073948,0,0;0.08636081627,0,0;-0.8532322921,0.3460208861,0];       
P=P*10;
ZP = P / 221.2;
ZT = (273.15 + T) / 647.3;
BL = l0 + l1 * ZT + l2 * ZT ^ 2;
BLP = l1 + 2 * l2 * ZT;
x = exp(B * (1 - ZT));
Z1 = 0;
for i = 1:1: 5
    Z2 = 0;
    for j = 1 :1: 3
        Z2 = Z2 + buv(i, j) * x ^ zuv(i, j);
    end
    Z1 = Z1 + Z2 * i * ZP ^ (i - 1);
end
Z4 = 0;
for i = 1 :1: 3
    Z2 = 0;
    Z3 = 0;
    for j = 1:1:3
        Z2 = Z2 + buv(i + 5, j) * x ^ zuv(i + 5, j);
        Z3 = Z3 + bul(i, j) * x ^ xul(i, j);
    end
%     Z4 = Z4 + Z2 * (i + 3) * ZP ^ (i + 2) / (1 + Z3 * ZP ^ (i + 3)) ^ 2;
    Z4 = Z4 + Z2 * (i + 3) * ZP ^ (-i -4) / ( Z3+ ZP ^ (-i - 3)) ^ 2;
end
Z6 = 0;
if (ZP < 0.1) 
    ZV = c1 * ZT / ZP - Z1 - Z4 + Z6;
else
    for IK = 1 :1: 7
        i = 8 - IK;
        Z6 = Z6 * x + b9(i);
    end
    Z6 = 11 * Z6 * abs((ZP / BL)) ^ 10; 
    ZV = c1 * ZT / ZP - Z1 - Z4 + Z6;
end
%ZV;
V = 0.00317 * ZV;
% V = 0.000293238774590658819898646268673 * ZV;
Z0 = 0;
for IK = 1:1: 5
    i = 6 - IK;
    Z0 = Z0 * ZT + (i - 2) * b0(i);
end
Z1 = 0;
for i = 1 :1: 5
    Z2 = 0;
    for j = 1:1: 3
        Z2 = Z2 + buv(i, j) * (1 + B * zuv(i, j) * ZT) * x ^ zuv(i, j);
    end
    Z1 = Z1 + Z2 * ZP ^ i;
end
Z5 = 0;
if (ZP < 0.005) %Then GoTo 100
    Z6 = 0;
else
   for i = 1 :1: 3
       Z4 = 0;
       for j = 1 :1: 3
           Z2 = 0;
           Z3 = 0;
           for K = 1 :1: 3
               Z2 = Z2 + xul(i, K) * bul(i, K) * x ^ xul(i, K);
               Z3 = Z3 + bul(i, K) * x ^ xul(i, K);
           end
           Z4 = buv(i + 5, j) * x ^ zuv(i + 5, j) * ((1 + zuv(i + 5, j) * B * ZT) - B * ZT * Z2 / (Z3 + 1 / ZP ^ (i + 3))) + Z4;
       end
       Z5 = Z5 + Z4 / (Z3 + 1 / ZP ^ (i + 3));
   end
   Z6 = 0;
end
if (ZP < 0.1) %Then GoTo 1100
    ZH = b1 * ZT - Z0 - Z1 - Z5 + Z6;
else
    for IK = 1 :1: 7
        i = 8 - IK;
        Z6 = Z6 * x + b9(i) * (1 + ZT * (10 * BLP / BL + B * (i - 1)));
    end
    Z6 = Z6 * ZP * abs((ZP / BL)) ^ 10;
    ZH = b1 * ZT - Z0 - Z1 - Z5 + Z6;
end
%ZH
H = ZH * 70.1204;
% H = ZH * 67.909913960258353166960191595494;
Z0 = 0;
for II = 1 :1:5
    i = 6 - II;
    Z0 = Z0 * ZT + (i - 1) * b0(i);
end
Z0 = Z0 / ZT;
Z1 = 0;
for i = 1 :1: 5
    for j = 1 :1: 3
        Z1 = Z1 + B * ZP ^ i * zuv(i, j) * buv(i, j) * x ^ zuv(i, j);
    end
end
Z5 = 0;
if (ZP < 0.005) %Then GoTo 1150
    Z5 = B * Z5;
else
    for i = 1 :1: 3
        Z4 = 0;
        for j = 1 :1: 3
            Z2 = 0;
            Z3 = 0;
            for K = 1 :1: 3
                Z2 = Z2 + x ^ xul(i, K) * bul(i, K) * xul(i, K);
                Z3 = Z3 + bul(i, K) * x ^ xul(i, K);
            end
            Z4 = Z4 + (zuv(i + 5, j) - Z2 / (1 / ZP ^ (i + 3) + Z3)) * buv(i + 5, j) * x ^ zuv(i + 5, j);
        end
        Z5 = Z5 + Z4 / (1 / ZP ^ (i + 3) + Z3);
    end
    Z5 = B * Z5;
end
Z6 = 0;
if (ZP < 0.1) %Then GoTo 1190
    ZS = b1 * log(ZT) - c1 * log(ZP) - Z0 - Z1 - Z5 + Z6;
else
    for IK = 1 :1: 7
        i = 8 - IK;
        Z6 = Z6 * x + (10 * BLP / BL + B * (i - 1)) * b9(i);
    end
    Z6 = Z6 * ZP * (ZP / BL) ^ 10;
    ZS = b1 * log(ZT) - c1 * log(ZP) - Z0 - Z1 - Z5 + Z6;
end
S= 108.3275143 * ZS / 1000;
