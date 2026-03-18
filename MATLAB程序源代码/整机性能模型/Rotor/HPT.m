function [GasOut,NErr,TrqOut,Data]=HPT(CoolFlow,GasIn,Rline,Nmech,data)
C_PSTD= data.Cons.C_PSTD;
C_TSTD=data.Cons.C_TSTD;

X_Ncor_r =data.HPTdate.X_Ncor_r;%相对换算转速
X_Beta = data.HPTdate.X_Beta;%beta
Y_Wcor =data.HPTdate.Y_Wcor;%换算流量
Y_Eff =data.HPTdate.Y_Eff;%换算效率
Y_PR =data.HPTdate.Y_PR;%换算压比

scale_Wc = data.scale.HPT.Wc;
scale_PR = data.scale.HPT.PR;
scale_Eff = data.scale.HPT.Eff;
scale_Nc = data.scale.HPT.Nc;
%% 入口参数
WIn=GasIn.W;
PtIn=GasIn.Pt;
TtIn=GasIn.Tt;
FARIn=GasIn.FAR;
htIn=GasIn.ht;
d=GasIn.d;

%% Stator后截面参数计算
W_Stator=WIn+CoolFlow.HPT_stator.W;
Pt_Stator=PtIn;
ht_Stator=(htIn*WIn+CoolFlow.HPT_stator.ht*CoolFlow.HPT_stator.W)*divby(W_Stator);
FAR_Stator=(WIn*FARIn)*divby(W_Stator);
Tt_Stator=hf_dp2t(ht_Stator,FAR_Stator,d,Pt_Stator);

S_Stator=ptf_d2s(Pt_Stator,Tt_Stator,FAR_Stator,d);
%% 插值部分
delta = PtIn / C_PSTD;
theta = Tt_Stator / C_TSTD;
A=length(X_Ncor_r);
B=length(X_Beta);
%根据物理转速求解相对换算转速，Nc为换算转速，Ncor_r为相对换算转速
Nc = Nmech*divby(sqrtT(theta));
Ncor_r = Nc *divby(scale_Nc); 
Correct_W=interp1g(data.Correction.HPT.Nc,data.Correction.HPT.W,Ncor_r);
Correct_Eff=interp1g(data.Correction.HPT.Nc,data.Correction.HPT.Eff,Ncor_r);
Correct_PR=interp1g(data.Correction.HPT.Nc,data.Correction.HPT.PR,Ncor_r);
%插值缩放得到换算流量Wc，从而得到真实流量WIn2
WcMap = interp2g(X_Beta,X_Ncor_r,Y_Wcor,Rline,min(Ncor_r,X_Ncor_r(end)));
Wc = WcMap * scale_Wc*Correct_W;%换算流量
WIn2 = Wc*divby(sqrtT(theta))*delta;%实际流量
if WIn2<0.1
    WIn2=0.1;
end
%稳定性控制
% if WIn2<3
%     y1=WIn2;
%     WcMap2 = interp2g(X_Beta,X_Ncor_r,Y_Wcor,Rline-0.1,Ncor_r);
%     Wc2 = WcMap2 * scale_Wc;%换算流量
%     y2 = Wc2*divby(sqrtT(theta))*delta;%实际流量
%     k=10*(y1-y2);
%     b=y1-k*Rline;
%     x0=(3-b)*divby(k);
%     WIn2=1+2*exp(x0-Rline);
% end

%插值缩放真实压比PR
PRMap = interp2g(X_Beta,X_Ncor_r,Y_PR,Rline,min(Ncor_r,X_Ncor_r(end)));
PR = scale_PR*(PRMap - 1) + 1 ;
    if PR<0.1
        PR=0.1;
    end
PR=PR*Correct_PR;
%插值缩放真实效率Eff
EffMap = interp2g(X_Beta,X_Ncor_r,Y_Eff,Rline,min(Ncor_r,X_Ncor_r(end)));
Eff = EffMap * scale_Eff*Correct_Eff;
if Eff<0.01
    Eff=0.01;
end
%% 特性修正
if data.HGC.HPT==1
    %OTDF修正
    [y3,y4]=OTDFCor(data.HPT_OTDF);%OTDF修正
    WIn2=WIn2*(1+0.01*y3);
    Eff=Eff*(1+0.01*y4);

    %间隙修正
    y5=HotClearanceCor(data.HPT_Clearance);
    PR=1+y5*(PR-1);

    %过渡段修正
    inputpara=[data.HPT_duct.Rout
    data.HPT_duct.Rratio
    data.HPT_duct.lgb_in
    data.HPT_duct.lgb_out
    data.HPT_duct.lr
    0.15
    0.15
    median([0.7, 1.1,Ncor_r])
    PR^(1/data.HPTstage)];
    y6=Tran_HPTo(inputpara);
    WIn2=WIn2*(1+0.01*y6(1));
    Eff=Eff*(1+0.01*y6(2));
end
%% Rotor后截面参数计算（不考虑rotor冷气掺混）
W_Rotor=W_Stator;
Pt_Rotor = Pt_Stator*divby(PR);
S_Rotor=S_Stator-log(abs(PR));
FAR_Rotor=FAR_Stator;
Tt_Rotor_ideal = spf_d2t(S_Rotor,Pt_Rotor,FAR_Rotor,d);
ht_Rotor_ideal = tf_dp2h(Tt_Rotor_ideal,FAR_Rotor,d,Pt_Rotor);
ht_Rotor=((ht_Rotor_ideal - ht_Stator)*Eff) + ht_Stator;
Tt_Rotor=hf_dp2t(ht_Rotor,FAR_Rotor,0,Pt_Rotor);
Pwrout=(ht_Stator-ht_Rotor)*W_Rotor;
TrqOut = Pwrout*divby(Nmech);
%% rotor冷气掺混
W_Rotor_after=W_Rotor+CoolFlow.HPT_rotor.W;
Pt_Rotor_after=Pt_Rotor;
ht_Rotor_after=(ht_Rotor*W_Rotor+CoolFlow.HPT_rotor.ht*CoolFlow.HPT_rotor.W)*divby(W_Rotor_after);
FAR_Rotor_after=(W_Rotor*FAR_Rotor)*divby(W_Rotor_after);
Tt_Rotor_after= hf_dp2t(ht_Rotor_after,FAR_Rotor_after,d,Pt_Rotor_after);
%% 构造残差方程
NErr = (W_Stator - WIn2)*divby(WIn);
%% 输出参数
if data.Metal_open
    Q=data.Metal.Ah_HPT*((Tt_Rotor_after+TtIn)/2-data.Metal.T_HPT);
    ht_Rotor_after=ht_Rotor_after-Q/WIn;
    Tt_Rotor_after = hf_dp2t(ht_Rotor_after,FAR_Rotor_after,d,Pt_Rotor_after);
    dT_matel=Q*divby(data.Metal.mcp_HPT);
else
    dT_matel=0;
    data.Metal.T_HPT=0;
end
GasOut.W = W_Rotor_after;
GasOut.ht= ht_Rotor_after;
GasOut.Tt = Tt_Rotor_after;
GasOut.Pt = Pt_Rotor_after;
GasOut.FAR= FAR_Rotor_after;
GasOut.d=d;
%
Data.Wc= Wc;
Data.W_Stator=W_Stator;
Data.W_rotor = W_Rotor;
Data.Nc = Nc;
Data.Nmech=Nmech;
Data.PR = PR;
Data.Eff=Eff;
Data.Pwrout= Pwrout;
Data.W41=W_Stator;
Data.T41=Tt_Stator;
Data.P41=Pt_Stator;
Data.W43=W_Rotor;
Data.T43=Tt_Rotor;
Data.P43=Pt_Rotor;
Data.Ncor_r=Ncor_r;
Data.Rline=Rline;
Data.dT_matel=dT_matel;
Data.Metal_T=data.Metal.T_HPT;
Data.Rline=Rline;
%%  容积动力学
% [dPt,dTt]=Volume(WIn + Wcoolout,W_out,PtOut,PtOut,TtOut,TtOut,FARcOut,data.Vols.HPT);
end