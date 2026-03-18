function [NErr,N_Data]=volute(GasIn,Pb,data)
%% 特性
Area=data.Area;
%% 入口参数
WIn=GasIn.W;
PtIn=GasIn.Pt;
TtIn=GasIn.Tt;
FARIn=GasIn.FAR;
d=0;
htin=GasIn.ht;
%出口背压
[~,Rg]=tfd2gammarRg(TtIn,FARIn,0);
Wc_g=WIn*sqrt(TtIn/288.15*Rg)*divby(PtIn/101325);
PR=1-(1-data.PR_volute_d)*(Wc_g*divby(data.W_volute_d))^2;
Pb=Pb*PR+data.P_loss_volute;
%% 出口参数计算
%如果扩压管入口总压>背压，则发生逆流
if (PtIn <= Pb)
    PtIn=Pb;
    Pb=GasIn.Pt;
    index=-1;
else
    index=1;
end
%出口压力为背压时的参数计算：熵，出口静温，出口静焓，出口体积，出口速度
S = ptf_d2s(PtIn,TtIn,FARIn,d)+log(abs(Pb/PtIn));%入口熵=出口熵
Ts = spf_d2t(S,Pb,FARIn,d);%出口静温
if (Ts > TtIn)
    Ts = TtIn;
end
hs = tf_dp2h(Ts,FARIn,d,Pb);%出口静焓
if (hs > htin)
    hs = htin;
end
[gammar,Rg]=tfd2gammarRg(Ts,FARIn,d);%此处需要使用燃气的物性参数
rhos = Pb * divby(Rg* Ts);%密度
V = sqrtT(2 * (htin - hs));%出口速度
Wout = index*Area*rhos*V;
MN_s = V*divby(sqrtT(gammar*Rg*Ts));
%% 残差方程
if (WIn == 0)
    NErr = 100;
else
    NErr = (WIn-Wout)*divby(WIn);
end
%% 输出参数
N_Data.Ath= Area;
% N_Data.Psth = Psth;
% N_Data.Tsth = Tsth;
N_Data.MN_s = MN_s;
N_Data.V = V;
N_Data.Woutcalc = Wout;
N_Data.PR=PtIn/GasIn.Pt;%总压恢复系数;
N_Data.W6=WIn;
N_Data.T6=TtIn;
N_Data.P6=PtIn;
N_Data.Ts8=Ts;
N_Data.Ps8=Pb;
% N_Data.V_s = V_s;
end