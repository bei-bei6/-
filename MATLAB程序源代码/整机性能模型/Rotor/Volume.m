function [dPt,dTt]=Volume(W_in,W_out,~,Pt_state,Tt_in,Tt_state,FAR,volume)
H_in = t2hc(Tt_in,FAR);
H_out = t2hc(Tt_state,FAR);
Cp = Cp_T(Tt_state);
R = gas_constant(FAR);
mnet = W_in-W_out;
hnet = H_in*W_in-H_out*W_out;
dPt=(R/volume)*((Tt_state-((H_out-R*Tt_state)/(Cp-R)))*mnet+(1/(Cp-R))*hnet);
dTt=((R*Tt_state)/(volume*Pt_state)/(Cp-R))*(-(H_out-R*Tt_state)*mnet+hnet);
% dTt=R*Tt_state/(Cv*Pt_state*volume)*hnet-R*Tt_state^2/(Pt_state*volume)*mnet;
% dPt=R*Tt_state/volume*mnet;
end