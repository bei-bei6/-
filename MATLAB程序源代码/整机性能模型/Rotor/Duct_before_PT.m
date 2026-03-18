function [GasOut_Out,Date]=Duct_before_PT(GasOut,data)
%计算换算流量
[~,Rg]=tfd2gammarRg(GasOut.Tt,GasOut.FAR,0);
Wc_g=GasOut.W*sqrt(GasOut.Tt/288.15*Rg)*divby(GasOut.Pt/101325);
PR=1-(1-data.beforePT_PR)*(Wc_g*divby(data.beforePT_Wc))^2;
    if PR<0.1
        PR=0.1;
    end
GasOut_Out.W = GasOut.W;
GasOut_Out.ht = GasOut.ht;
GasOut_Out.Tt = GasOut.Tt;
GasOut_Out.Pt = GasOut.Pt*PR;
GasOut_Out.FAR = GasOut.FAR;
GasOut_Out.d = 0;
Date.PR=PR;