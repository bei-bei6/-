function [S, Ts, hs, rhos, V]=PcalcStat(Pt,Ps,Tt,ht,FAR,Rt)

S = pt2sc(Pt, Tt, FAR);
Ts = sp2tc(S,Ps,FAR);
if (Ts > Tt)
    Ts = Tt;
end
hs = t2hc(Ts,FAR);
if (hs > ht)
    hs = ht;
end
Rs = Rt;
rhos = Ps * divby(Rs* Ts);
V = sqrtT(2 * (ht - hs));
end