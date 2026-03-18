function [GasPthCharOut,B_Data]=Burner(GasPthCharIn,FAR_Burner,data)
%% 燃料热值
LHV=data.Combustor.LHV;
%% 入口参数
WfIn=GasPthCharIn.W*FAR_Burner;%稳态
WIn=GasPthCharIn.W;
htin=GasPthCharIn.ht;
PtIn=GasPthCharIn.Pt;
TtIn=GasPthCharIn.Tt;
d_in=GasPthCharIn.d;
%% 燃烧效率计算
%燃烧效率计算方法（1），与GASTURB相同
if PtIn<0
   PtIn=0.1;
end
omiga=WIn/((PtIn)^1.8*exp(TtIn/300));
omiga_r=omiga/data.Combustor.omiga_d;
a=log10(1-data.Combustor.Eff);
b=data.Combustor.b;
Eff=1-10^(a+b*log10(abs(omiga_r)));
if Eff<0.1
    Eff=0.1;
end
    
%燃烧效率计算方法（2）
%{
if isempty(data.Combustor.Eff)
    EAC=data.Combustor.EAC;
    if EAC<=3
        Eff=1-0.8*(WIn*divby(0.05*TtIn*PtIn^1.25))^2*(1+(1-3*divby(EAC))^2)^2;
    else
        Eff=1-0.8*(WIn*divby(0.05*TtIn*PtIn^1.25))^2*(1+(1-EAC/3)^2)^2;    
    end  
else   
    Eff=data.Combustor.Eff;
end
%}
WOut = WIn + WfIn;
FAROut = FAR_Burner;
htOut = (WIn*htin + WfIn*LHV*Eff)*divby(WOut);
d_out=d_in*divby(1+FAROut*(1+d_in));
TtOut = hf_dp2t(htOut,FAROut,d_out,PtIn);%杩戜技澶勭悊锛氬皢鍏ュ彛鍘嬪姏浣滀负鍑哄彛鍘嬪姏璁＄畻
%% 总压损失系数计算
% if isempty(data.Combustor.PR)
    %压比计算方法1

[~,Rg]=tfd2gammarRg(TtIn,0,d_in);
Wc_g=WIn*sqrt(TtIn/288.15*Rg)*divby(PtIn/101325);
PR=1-(1-data.Combustor.PR)*(Wc_g*divby(data.Wc_Combustor_d))^2;

if data.HGC.Burner==1
    x=data.Combustor.x;
    y=data.Combustor.y;
    f1   = 0.7412*x+0.9123;
    f2   =-12.769*y^7+9.729*y^6+5.479*y^5-5.172*y^4-0.112*y^3+0.548*y^2-0.14*y+1;
    PR  = PR*f1*f2;
end

% PR=PR*Correct_PR;
if PR<0.1
    PR=0.1;
end

PtOut =PR * PtIn;
%% 鍑哄彛鍙傛暟
GasPthCharOut.W = WOut;
GasPthCharOut.ht = htOut;
GasPthCharOut.Tt = hf_dp2t(htOut,FAROut,d_out,PtOut);
GasPthCharOut.Pt = PtOut;
GasPthCharOut.FAR = FAROut;
GasPthCharOut.d = d_out;

B_Data.heat = WfIn*LHV;
B_Data.PR = PR;
B_Data.Eff = Eff;
B_Data.Wf = WfIn;
%%  dynamics
% [dPt,dTt]=Volume(WIn+WfIn,W_out,PtOut,PtOut,TtOut,TtOut,FARcOut,data.Vols.Burner);
if ~isreal(htOut)
    w=5;
end
end