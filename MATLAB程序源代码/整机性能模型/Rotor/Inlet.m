function [GasOut_Inlet,Data]=Inlet(W,data)

[~,Rg]=tfd2gammarRg(data.T0,0,0);
Wc_g=W*sqrt(data.T0/288.15*Rg)*divby(data.P0/101325);
PR=1-(1-data.PR_inlet_d)*(Wc_g*divby(data.W_inlet_d))^2;

GasOut_Inlet.W=W;%流量
GasOut_Inlet.Tt=data.T0;%总温
GasOut_Inlet.Pt=data.P0*PR-data.P_loss_inlet;%总压
GasOut_Inlet.FAR = 0;%油气�?
GasOut_Inlet.d = ptRH2d(GasOut_Inlet.Pt,data.T0,data.RH);%含湿�?
GasOut_Inlet.ht = tf_dp2h(data.T0,0,GasOut_Inlet.d,GasOut_Inlet.Pt);%总焓
Data.PR=PR;
end