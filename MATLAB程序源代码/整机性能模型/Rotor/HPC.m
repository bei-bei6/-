function [GasOut_HPC,CoolFlow,NErr,TrqOut,Data]=HPC(GasOut,Rline,Nmech,data)
%% 特性
C_PSTD =data.Cons.C_PSTD;%海平面大气压
C_TSTD =data.Cons.C_TSTD;%海平面静温 

X_Ncor_r =data.HPCdate.X_Ncor_r;%相对换算转速
X_Beta = data.HPCdate.X_Beta;%beta
Y_Wcor =data.HPCdate.Y_Wcor;%换算流量
Y_Eff =data.HPCdate.Y_Eff;%换算效率
Y_PR =data.HPCdate.Y_PR;%换算压比

scale_Wc = data.scale.HPC.Wc;
scale_PR = data.scale.HPC.PR;
scale_Eff = data.scale.HPC.Eff;
scale_Nc = data.scale.HPC.Nc;

% X_Surge_Wc=Y_Wcor(:,end)';%喘振线横坐标，这里需要检查
% Y_Surge_PR=Y_PR(:,end)';%喘振线纵坐标，这里需要检查
X_Surge_Wc=data.HPCdate.X_Surge_Wc;%喘振线横坐标，这里需要检查
Y_Surge_PR=data.HPCdate.Y_Surge_PR;%喘振线纵坐标，这里需要检查
%% 入口参数
WIn2=GasOut.W;
TtIn=GasOut.Tt;
PtIn=GasOut.Pt;
FARcIn=0;
htin = GasOut.ht;
d=GasOut.d;
Sin = ptf_d2s(PtIn,TtIn,FARcIn,d);

delta = PtIn / C_PSTD;
theta = TtIn / C_TSTD;
%Wcin = WIn*sqrtT(theta)*divby(delta);

%% 插值部分

% A=length(X_Ncor_r);
% B=length(X_Beta);
% D=length(X_Surge_Wc);
%根据物理转速求解相对换算转速，Nc为换算转速，Ncor_r为相对换算转速
Nc = Nmech*divby(sqrtT(theta));
Ncor_r = Nc *divby(scale_Nc);
Correct_W=interp1g(data.Correction.HPC.Nc,data.Correction.HPC.W,Ncor_r);
Correct_Eff=interp1g(data.Correction.HPC.Nc,data.Correction.HPC.Eff,Ncor_r);
Correct_PR=interp1g(data.Correction.HPC.Nc,data.Correction.HPC.PR,Ncor_r);
%插值缩放得到换算流量Wc，从而得到真实流量WIn
WcMap = interp2g(X_Beta,X_Ncor_r,Y_Wcor,Rline,Ncor_r);
Wc = WcMap * scale_Wc*Correct_W;%换算流量
WIn = Wc*divby(sqrtT(theta))*delta;%实际流量
if WIn<0.1
    WIn=0.1;
end
%稳定性控制
% if WIn<5
%     y1=WIn;
%     WcMap2 = interp2g(X_Beta,X_Ncor_r,Y_Wcor,Rline+0.1,Ncor_r);
%     Wc2 = WcMap2 * scale_Wc;%换算流量
%     y2 = Wc2*divby(sqrtT(theta))*delta;%实际流量
%     k=10*(y2-y1);
%     b=y1-k*Rline;
%     x0=(5-b)*divby(k);
%     WIn=2+3*exp(x0-Rline);
% end

%插值缩放真实压比PR
PRMap = interp2g(X_Beta,X_Ncor_r,Y_PR,Rline,Ncor_r);
PR = scale_PR*(PRMap - 1) + 1 ;
PR=PR*Correct_PR;
if PR<0.1
    PR=0.1;
end
%插值缩放真实效率Eff
EffMap = interp2g(X_Beta,X_Ncor_r,Y_Eff,Rline,Ncor_r);
Eff = EffMap * scale_Eff*Correct_Eff;
if Eff<0.01
    Eff=0.01;
end
%插值得到喘振裕度
% try
Surge_PR_Map = interp1g(X_Surge_Wc,Y_Surge_PR,WcMap);
% catch
%     d=5;
% end
Surge_PR = scale_PR*(Surge_PR_Map - 1) + 1;
SM = (Surge_PR - PR)*divby(PR) * 100;
%% 出口参数计算-1
PtOut = PtIn*PR;
Sout = Sin+log(abs(PR));
TtIdealout = spf_d2t(Sout,PtOut,FARcIn,d);
htIdealout = tf_dp2h(TtIdealout,FARcIn,d,PtOut);
htOut = ((htIdealout - htin)*divby(Eff)) + htin;
TtOut = hf_dp2t(htOut,FARcIn,d,PtOut);
%% 空气系统与放气系统
%高压涡轮导向器
CoolFlow.HPT_stator.W=data.SAS.Ratio(1)*WIn;%冷气流量
CoolFlow.HPT_stator.ht=htin+(htOut - htin)*data.SAS.Position(1);%冷气焓
CoolFlow.HPT_stator.Pt=PtIn+(PtOut - PtIn)*data.SAS.Position(1);%冷气总压
CoolFlow.HPT_stator.Tt=hf_dp2t(CoolFlow.HPT_stator.ht,0,d,CoolFlow.HPT_stator.Pt);%冷气总温
W_bleeds=CoolFlow.HPT_stator.W;%空气系统放气量
Power_bleeds=CoolFlow.HPT_stator.W*(CoolFlow.HPT_stator.ht-htOut);%因引气导致少做的功

%高压涡轮转子
CoolFlow.HPT_rotor.W=data.SAS.Ratio(2)*WIn;
CoolFlow.HPT_rotor.ht=htin+(htOut - htin)*data.SAS.Position(2);
CoolFlow.HPT_rotor.Pt=PtIn+(PtOut - PtIn)*data.SAS.Position(2);
CoolFlow.HPT_rotor.Tt=hf_dp2t(CoolFlow.HPT_rotor.ht,0,d,CoolFlow.HPT_rotor.Pt);
W_bleeds=W_bleeds+CoolFlow.HPT_rotor.W;
Power_bleeds=Power_bleeds+CoolFlow.HPT_rotor.W*(CoolFlow.HPT_rotor.ht-htOut);

%动力涡轮导向器
CoolFlow.PT_stator.W=data.SAS.Ratio(3)*WIn;
CoolFlow.PT_stator.ht=htin+(htOut - htin)*data.SAS.Position(3);
CoolFlow.PT_stator.Pt=PtIn+(PtOut - PtIn)*data.SAS.Position(3);
CoolFlow.PT_stator.Tt=hf_dp2t(CoolFlow.PT_stator.ht,0,d,CoolFlow.PT_stator.Pt);
W_bleeds=W_bleeds+CoolFlow.PT_stator.W;
Power_bleeds=Power_bleeds+CoolFlow.PT_stator.W*(CoolFlow.PT_stator.ht-htOut);

%动力涡轮转子
CoolFlow.PT_rotor.W=data.SAS.Ratio(4)*WIn;
CoolFlow.PT_rotor.ht=htin+(htOut - htin)*data.SAS.Position(4);
CoolFlow.PT_rotor.Pt=PtIn+(PtOut - PtIn)*data.SAS.Position(4);
CoolFlow.PT_rotor.Tt=hf_dp2t(CoolFlow.PT_rotor.ht,0,d,CoolFlow.PT_rotor.Pt);
W_bleeds=W_bleeds+CoolFlow.PT_rotor.W;
Power_bleeds=Power_bleeds+CoolFlow.PT_rotor.W*(CoolFlow.PT_rotor.ht-htOut);

%放气系统
% if exist('data.HPCvalve')%瞬态计算定义了，稳态计算没有定义
%     if data.HPCvalve==1
%         Deflate.W=data.HPCDeflate.Ratio*WIn;%放气流量
%         Deflate.ht=htin+(htOut - htin)*data.HPCDeflate.Position;%放气焓
%     else
%         Deflate.W=0;%放气流量
%         Deflate.ht=htOut;%放气焓
%     end
% else
    Deflate.W=data.HPCDeflate.Ratio*WIn;%放气流量
    Deflate.ht=htin+(htOut - htin)*data.HPCDeflate.Position;%放气焓
% end
%% 出口参数计算-2
WOut = WIn -W_bleeds-Deflate.W;%出口流量
Pwrour_t = WIn * (htin - htOut);%不考虑空气系统时候的输出功率
Pwrout = Pwrour_t - Power_bleeds-Deflate.W*(Deflate.ht-htOut);%考虑空气系统的输出功率
TrqOut = Pwrout*divby(Nmech);
%% 构造残差方程
NErr = (WIn - WIn2)*divby(WIn);
%% 输出参数
if data.Metal_open
    Q=data.Metal.Ah_HPC*((TtOut+TtIn)/2-data.Metal.T_HPC);
    htOut=htOut-Q/WIn;
    TtOut = hf_dp2t(htOut,FARcIn,d,PtOut);
    dT_matel=Q*divby(data.Metal.mcp_HPC);
else
    dT_matel=0;
    data.Metal.T_HPC=0;
end
GasOut_HPC.W = WOut;
GasOut_HPC.ht = htOut;
GasOut_HPC.Tt = TtOut;
GasOut_HPC.Pt = PtOut;
GasOut_HPC.FAR = 0;
GasOut_HPC.d = 0;
%
Data.SM = SM;
Data.WIn = WIn;
Data.Wcin = Wc;
Data.Nc = Nc;
Data.PR = PR;
Data.Eff=Eff;
Data.Ncor_r = Ncor_r;
Data.WcMap = WcMap;
Data.PRMap = PRMap;
Data.EffMap = EffMap;
Data.SurgePR = Surge_PR;
Data.Wbleeds = W_bleeds;
Data.Pwrb4bleed = Pwrour_t;
Data.PwrBld = Power_bleeds;
Data.Pwrout = Pwrout;
Data.Test = 0;
Data.Nmech=Nmech;
Data.W_3=GasOut_HPC.W+WIn*(data.SAS.Ratio(1)+data.SAS.Ratio(2));
Data.dT_matel=dT_matel;
Data.Metal_T=data.Metal.T_HPC;
Data.Rline=Rline;
end