function [GasOut_Out,Date]=Duct_after_PT(GasOut,data)
%计算换算流量
[~,Rg]=tfd2gammarRg(GasOut.Tt,GasOut.FAR,0);
Wc_g=GasOut.W*sqrt(GasOut.Tt/288.15*Rg)*divby(GasOut.Pt/101325);
PR=1-(1-data.afterPT_PR)*(Wc_g*divby(data.afterPT_Wc))^2;
    if PR<0.1
        PR=0.1;
    end
GasOut_Out.W = GasOut.W;
GasOut_Out.ht = GasOut.ht;
GasOut_Out.Tt = GasOut.Tt;
GasOut_Out.Pt = GasOut.Pt*PR;
GasOut_Out.FAR = GasOut.FAR;
GasOut_Out.d = GasOut.d;
Date.PR=PR;
end