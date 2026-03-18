function NErr=ATran_rho(rhos2,data)
R=data.Cons.R;
rhos=(data.rhos1+rhos2)/2;%平均密度
Pt2=data.GasIn.Pt-data.K*data.W^2/(2*rhos*data.A2^2);
Ps2=PstarMa2P(Pt2,data.Ma2);
Ts2=TstarMa2T(data.GasIn.Tt,data.Ma2);
rhos2n=Ps2/(R*Ts2);
NErr=rhos2n-rhos2;
end