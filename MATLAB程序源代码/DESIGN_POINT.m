%设计点计算程序
clc,clear,close All
%% INPUT
%入口
inlet.T=288.15;%环境温度
Amb.P=101325;%环境压力
inlet.W=70.8;%进口流量
inlet.PR=0.965;%进气道总压恢复系数
% 空气系统
data.SAS.Position =[1;1;0.822;0.548];           %引气位置：高导，高转，动导，动转
data.SAS.Ratio =[0.09;0.05;0.05;0.02];   %引气比例：高导，高转，动导，动转
%放气系统
data.HPCDeflate.Position=1;     %压气机放气位置
data.HPCDeflate.Ratio=0.0002;      %压气机放气量
%LPC
HPC.Pr=23.5;
HPC.Eff=0.87;
%燃烧室
Burner.T=1507.99;
heatvalue=32450000;
Burner.PR=0.95;
Burner.Eff=0.999;
%高压涡轮
HPT.Pr=3.2355;%迭代初值，根据功率相同重新调整
HPT.Eff=0.925;
HPS.Eff=0.99;
%高低压涡轮之间的支板结构总压损失
HPT.DUCTloss=0.985;
%低压涡轮
LPT.Eff=0.92;
LPS.Eff=0.995;
Outlet.PR=1.05;%ps8/p0排气系统压力损失
Volute.PR=1.04436;%排气蜗落压比，p6/ps8
LPT.DUCTloss=0.995;%动力涡轮后压力损失，p6/p5
%%特性图上设计点参数
%压气机
HPC.beta=0.5;
HPC.Ncor_r=1;
%高压涡轮
HPT.beta=0.5;
HPT.Ncor_r=1;
%动力涡轮
LPT.beta=0.7;
LPT.Ncor_r=1;
%轴转速
HPS.speed=14000;%燃机高速轴的设计点物理转速
LPS.speed=6000;%燃机动力轴的设计点物理转速

%%
format long
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\parameter'));
load([pwd,'/parameter/character.mat'])

MAP.HPC.Nc=HPCdate.X_Ncor_r;
MAP.HPC.Wc=HPCdate.Y_Wcor;
MAP.HPC.Eff=HPCdate.Y_Eff;
MAP.HPC.PR=HPCdate.Y_PR;
MAP.HPC.Rline=HPCdate.X_Beta;

MAP.HPT.Nc=HPTdate.X_Ncor_r;
MAP.HPT.Wc=HPTdate.Y_Wcor;
MAP.HPT.Eff=HPTdate.Y_Eff;
MAP.HPT.PR=HPTdate.Y_PR;

MAP.PT.Nc=PTdate.X_Ncor_r;
MAP.PT.Wc=PTdate.Y_Wcor;
MAP.PT.Eff=PTdate.Y_Eff;
MAP.PT.PR=PTdate.Y_PR;
save([pwd,'/parameter/MAP.mat'],'MAP')
%% inlet：入口滞止参数
d=0;
inlet.P=Amb.P*inlet.PR;
inlet.H=tf_dp2h(inlet.T,0);
[~,dp.R_inlet_d]=tfd2gammarRg(inlet.T,0,d);
%% LPC：低压压气机出口参数
%出口参数计算-1
HPC.P=inlet.P*HPC.Pr;%压力
HPC.S=ptf_d2s(inlet.P,inlet.T,0);%入口熵
TtIdealout = spf_d2t(HPC.S+log(HPC.Pr),HPC.P,0);%等熵过程时的出口温度
htIdealout = tf_dp2h(TtIdealout,0);%等熵过程中的出口焓
HPC.H = ((htIdealout - inlet.H)*divby(HPC.Eff)) + inlet.H;
HPC.T = hf_dp2t(HPC.H,0);
%空气系统与放气系统
%高压涡轮导向器
CoolFlow.HPT_stator.W=data.SAS.Ratio(1)*inlet.W;%冷气流量
CoolFlow.HPT_stator.ht=inlet.H+(HPC.H - inlet.H)*data.SAS.Position(1);%冷气焓
CoolFlow.HPT_stator.Pt=inlet.P+(HPC.P - inlet.P)*data.SAS.Position(1);%冷气总压
CoolFlow.HPT_stator.Tt=hf_dp2t(CoolFlow.HPT_stator.ht,0,d,CoolFlow.HPT_stator.Pt);%冷气总温
W_bleeds=CoolFlow.HPT_stator.W;%空气系统放气量
Power_bleeds=CoolFlow.HPT_stator.W*(CoolFlow.HPT_stator.ht-HPC.H);%因引气导致少做的功

%高压涡轮转子
CoolFlow.HPT_rotor.W=data.SAS.Ratio(2)*inlet.W;
CoolFlow.HPT_rotor.ht=inlet.H+(HPC.H - inlet.H)*data.SAS.Position(2);
CoolFlow.HPT_rotor.Pt=inlet.P+(HPC.P - inlet.P)*data.SAS.Position(2);
CoolFlow.HPT_rotor.Tt=hf_dp2t(CoolFlow.HPT_rotor.ht,0,d,CoolFlow.HPT_rotor.Pt);
W_bleeds=W_bleeds+CoolFlow.HPT_rotor.W;
Power_bleeds=Power_bleeds+CoolFlow.HPT_rotor.W*(CoolFlow.HPT_rotor.ht-HPC.H);

%动力涡轮导向器
CoolFlow.PT_stator.W=data.SAS.Ratio(3)*inlet.W;
CoolFlow.PT_stator.ht=inlet.H+(HPC.H - inlet.H)*data.SAS.Position(3);
CoolFlow.PT_stator.Pt=inlet.P+(HPC.P - inlet.P)*data.SAS.Position(3);
CoolFlow.PT_stator.Tt=hf_dp2t(CoolFlow.PT_stator.ht,0,d,CoolFlow.PT_stator.Pt);
W_bleeds=W_bleeds+CoolFlow.PT_stator.W;
Power_bleeds=Power_bleeds+CoolFlow.PT_stator.W*(CoolFlow.PT_stator.ht-HPC.H);

%动力涡轮转子
CoolFlow.PT_rotor.W=data.SAS.Ratio(4)*inlet.W;
CoolFlow.PT_rotor.ht=inlet.H+(HPC.H - inlet.H)*data.SAS.Position(4);
CoolFlow.PT_rotor.Pt=inlet.P+(HPC.P - inlet.P)*data.SAS.Position(4);
CoolFlow.PT_rotor.Tt=hf_dp2t(CoolFlow.PT_rotor.ht,0,d,CoolFlow.PT_rotor.Pt);
W_bleeds=W_bleeds+CoolFlow.PT_rotor.W;
Power_bleeds=Power_bleeds+CoolFlow.PT_rotor.W*(CoolFlow.PT_rotor.ht-HPC.H);

%放气系统
Deflate.W=data.HPCDeflate.Ratio*inlet.W;%放气流量
Deflate.ht=inlet.H+(HPC.H - inlet.H)*data.HPCDeflate.Position;%放气焓

%出口参数计算-2
HPC.W = inlet.W -W_bleeds-Deflate.W;%出口流量
Pwrour_t = inlet.W * (inlet.H - HPC.H);%不考虑空气系统时候的输出功率
HPC.Power = Pwrour_t - Power_bleeds-Deflate.W*(Deflate.ht-HPC.H );%考虑空气系统的输出功率
HPC.Power=-HPC.Power;%正数
HPC.Wc=HPC.W*sqrt(HPC.T/288.15)/(HPC.P/101325);
%% Burner：燃烧室
Burner.P=HPC.P*Burner.PR;
left=0;
right=0.1;
while 1
    FAR=0.5*(right+left);
    WfIn=HPC.W*FAR;%燃油量
    WOut = HPC.W + WfIn;
    htOut = (HPC.W*HPC.H + WfIn*heatvalue*Burner.Eff)*divby(WOut);
    TtOut = hf_dp2t(htOut,FAR,0,Burner.P);
    if TtOut<Burner.T
        left=FAR;
    else
        right=FAR;
    end
    if abs(TtOut-Burner.T)<0.0000001
        break;
    end
end
Burner.W=WOut;
Burner.H=htOut;
fuel=Burner.W-HPC.W;
FAR=fuel/HPC.W;%油气比
dp.omiga=HPC.W/(HPC.P^1.8*exp(HPC.T/300));
%% HPT:高压涡轮
%高压涡轮落压比
right=20;left=1;
while 1
% Stator后截面参数计算
    W_Stator=Burner.W+CoolFlow.HPT_stator.W;
    Pt_Stator=Burner.P;
    ht_Stator=(Burner.H*Burner.W+CoolFlow.HPT_stator.ht*CoolFlow.HPT_stator.W)*divby(W_Stator);
    FAR_Stator=(Burner.W*FAR)*divby(W_Stator);
    HPT.Tt_Stator=hf_dp2t(ht_Stator,FAR_Stator,d,Pt_Stator);
    S_Stator=ptf_d2s(Pt_Stator,HPT.Tt_Stator,FAR_Stator,d); 
    
    PR1=0.5*(right+left);
% Rotor后截面参数计算（不考虑rotor冷气掺混）
    W_Rotor=W_Stator;
    Pt_Rotor = Pt_Stator*divby(PR1);
    S_Rotor=S_Stator-log(PR1);
    FAR_Rotor=FAR_Stator;
    Tt_Rotor_ideal = spf_d2t(S_Rotor,Pt_Rotor,FAR_Rotor,d);
    ht_Rotor_ideal = tf_dp2h(Tt_Rotor_ideal,FAR_Rotor,d,Pt_Rotor);
    ht_Rotor=((ht_Rotor_ideal - ht_Stator)*HPT.Eff) + ht_Stator;
    HPT.Power=(ht_Stator-ht_Rotor)*W_Rotor;
    if HPT.Power*HPS.Eff<HPC.Power
        left=PR1;
    else
        right=PR1;
    end
    if abs(HPT.Power*HPS.Eff-HPC.Power)<0.001
        break;
    end
end
% rotor冷气掺混
HPT.W=W_Rotor+CoolFlow.HPT_rotor.W;
HPT.P=Pt_Rotor;
HPT.H=(ht_Rotor*W_Rotor+CoolFlow.HPT_rotor.ht*CoolFlow.HPT_rotor.W)*divby(HPT.W);
HPT.FAR=(W_Rotor*FAR_Rotor)*divby(HPT.W);
HPT.T= hf_dp2t(HPT.H,HPT.FAR,d,HPT.P);
HPT.Pr=PR1;
HPT.Wc=HPT.W*sqrt(HPT.T/288.15)/(HPT.P/101325);
HPT.W_Stator=W_Stator;
%% DUCT
HPT.P=HPT.P*HPT.DUCTloss;
%% LPT：低压涡轮
Outlet.P=Amb.P;%出口环境压力
LPT.P=Outlet.P*Outlet.PR*Volute.PR/LPT.DUCTloss;
% Stator后截面参数计算
W_Stator=HPT.W+CoolFlow.PT_stator.W;
Pt_Stator=HPT.P;
ht_Stator=(HPT.H*HPT.W+CoolFlow.PT_stator.ht*CoolFlow.PT_stator.W)*divby(W_Stator);
FAR_Stator=(HPT.W*HPT.FAR)*divby(W_Stator);
LPT.Tt_Stator=hf_dp2t(ht_Stator,FAR_Stator,d,Pt_Stator);
S_Stator=ptf_d2s(Pt_Stator,LPT.Tt_Stator,FAR_Stator,d); 
    
PR1=HPT.P/LPT.P;
% Rotor后截面参数计算（不考虑rotor冷气掺混）
W_Rotor=W_Stator;
Pt_Rotor = Pt_Stator*divby(PR1);
S_Rotor=S_Stator+log(1/PR1);
FAR_Rotor=FAR_Stator;
Tt_Rotor_ideal = spf_d2t(S_Rotor,Pt_Rotor,FAR_Rotor,d);
ht_Rotor_ideal = tf_dp2h(Tt_Rotor_ideal,FAR_Rotor,d,Pt_Rotor);
ht_Rotor=((ht_Rotor_ideal - ht_Stator)*LPT.Eff) + ht_Stator;
LPT.Power=(ht_Stator-ht_Rotor)*W_Rotor*LPS.Eff;
Tt_Roter= hf_dp2t(ht_Rotor,FAR_Rotor);
% rotor冷气掺混
LPT.W=W_Rotor+CoolFlow.PT_rotor.W;
LPT.P=Pt_Rotor;
LPT.H=(ht_Rotor*W_Rotor+CoolFlow.PT_rotor.ht*CoolFlow.PT_rotor.W)*divby(LPT.W);
LPT.FAR=(W_Rotor*FAR_Rotor)*divby(LPT.W);
LPT.T= hf_dp2t(LPT.H,LPT.FAR,d,LPT.P);
LPT.Pr=PR1;
LPT.Wc=LPT.W*sqrt(LPT.T/288.15)/(LPT.P/101325);
LPT.W_Stator=W_Stator;
%% DUCT
LPT.P=LPT.P*LPT.DUCTloss;

%% Volute: 排气蜗壳，计算出口截面积
Volute.Ps=Outlet.P*Outlet.PR;
Volute.S = ptf_d2s(LPT.P,LPT.T,LPT.FAR)+log(Volute.Ps/LPT.P);%入口熵=出口熵
Volute.Ts = spf_d2t(Volute.S,Volute.Ps,LPT.FAR);%出口静温
Volute.Hs = tf_dp2h(Volute.Ts,LPT.FAR);%出口静焓
[gammar,Rg]=tfd2gammarRg(Volute.Ts,LPT.FAR,0);
rhos = Volute.Ps * divby(Rg* Volute.Ts);%密度
V = sqrtT(2 * (LPT.H - Volute.Hs));%出口速度

Aare=LPT.W/(V*rhos);
MN=V*divby(sqrtT(gammar*Rg*Volute.Ts));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 特性图上设计点参数
%压气机
map.HPC.Wc = interp2g(HPCdate.X_Beta,HPCdate.X_Ncor_r,HPCdate.Y_Wcor,HPC.beta,HPC.Ncor_r);
map.HPC.PR = interp2g(HPCdate.X_Beta,HPCdate.X_Ncor_r,HPCdate.Y_PR,HPC.beta,HPC.Ncor_r);
map.HPC.Eff = interp2g(HPCdate.X_Beta,HPCdate.X_Ncor_r,HPCdate.Y_Eff,HPC.beta,HPC.Ncor_r);
%高压涡轮
map.HPT.Wc = interp2g(HPTdate.X_Beta,HPTdate.X_Ncor_r,HPTdate.Y_Wcor,HPT.beta,HPT.Ncor_r);
map.HPT.PR = interp2g(HPTdate.X_Beta,HPTdate.X_Ncor_r,HPTdate.Y_PR,HPT.beta,HPT.Ncor_r);
map.HPT.Eff = interp2g(HPTdate.X_Beta,HPTdate.X_Ncor_r,HPTdate.Y_Eff,HPT.beta,HPT.Ncor_r);
%动力涡轮
map.LPT.Wc = interp2g(PTdate.X_Beta,PTdate.X_Ncor_r,PTdate.Y_Wcor,LPT.beta,LPT.Ncor_r);
map.LPT.PR = interp2g(PTdate.X_Beta,PTdate.X_Ncor_r,PTdate.Y_PR,LPT.beta,LPT.Ncor_r);
map.LPT.Eff = interp2g(PTdate.X_Beta,PTdate.X_Ncor_r,PTdate.Y_Eff,LPT.beta,LPT.Ncor_r);
%% 燃机设计点参数
%HPC
theta=inlet.T/288.15;
delta=inlet.P/101325;
real.HPC.Wc=inlet.W*sqrt(theta)/delta;
real.HPC.Eff=HPC.Eff;
real.HPC.PR=HPC.Pr;

%HPT
theta=HPT.Tt_Stator/288.15;
delta=Burner.P/101325;
real.HPT.Wc=HPT.W_Stator*sqrt(theta)/delta;
real.HPT.Eff=HPT.Eff;
real.HPT.PR=HPT.Pr;

%LPT
theta=LPT.Tt_Stator/288.15;
delta=HPT.P/101325;
real.LPT.Wc=LPT.W_Stator*sqrt(theta)/delta;
real.LPT.Eff=LPT.Eff;
real.LPT.PR=LPT.Pr;

%% 性能匹配参数
HPC.speed=HPS.speed/HPC.Ncor_r;%部件特性图换算转速为1时对应的设计点物理转速
HPT.speed=HPS.speed/HPT.Ncor_r;
LPT.speed=LPS.speed/LPT.Ncor_r;%

scale.HPC.Wc=real.HPC.Wc/map.HPC.Wc;
scale.HPC.Eff=real.HPC.Eff/map.HPC.Eff;
scale.HPC.PR=(real.HPC.PR-1)/(map.HPC.PR-1);
scale.HPC.Nc=HPC.speed/sqrt(inlet.T/288.15);%

scale.HPT.Wc=real.HPT.Wc/map.HPT.Wc;
scale.HPT.Eff=real.HPT.Eff/map.HPT.Eff;
scale.HPT.PR=(real.HPT.PR-1)/(map.HPT.PR-1);
scale.HPT.Nc=HPT.speed/sqrt(HPT.Tt_Stator/288.15);

scale.PT.Wc=real.LPT.Wc/map.LPT.Wc;
scale.PT.Eff=real.LPT.Eff/map.LPT.Eff;
scale.PT.PR=(real.LPT.PR-1)/(map.LPT.PR-1);
scale.PT.Nc=LPT.speed/sqrt(LPT.Tt_Stator/288.15);
%% 输出
%实际入口流量；HPC beta；燃烧室油气比；HPT beta;PT beta;高压轴物理转速
x0=[inlet.W;HPC.beta;FAR;HPT.beta;LPT.beta;HPS.speed];
save([pwd,'/parameter/x0.mat'],'x0')
save([pwd,'/parameter/scale.mat'],'scale')
%
[~,inlet_Rg]=tfd2gammarRg(inlet.T,0,0);
dp.Wc_inlet_d=inlet.W*sqrt(inlet.T/288.15*inlet_Rg)/(Amb.P/101325);%进气道入口换算流量
[~,HPC_Rg]=tfd2gammarRg(HPC.T,0,0);
dp.Wc_Combustor_d=HPC.Wc*sqrt(HPC_Rg);%燃烧室入口换算流量
[~,HPT_Rg]=tfd2gammarRg(HPT.T,HPT.FAR,0);
dp.beforePT_Wc=HPT.Wc*sqrt(HPT_Rg);%动力涡轮前换算流量
dp.beforePT_PR=HPT.DUCTloss;
[~,LPT_Rg]=tfd2gammarRg(LPT.T,LPT.FAR,0);
dp.afterPT_Wc=LPT.Wc*sqrt(LPT_Rg);%动力涡轮后换算流量
dp.afterPT_PR=LPT.DUCTloss;
dp.Wc_volute_d=LPT.W*sqrt(LPT.T/288.15)/(LPT.P/101325)*sqrt(LPT_Rg);%排气系统换算流量



dp.Area=Aare;
dp.PR_inlet_d=inlet.PR;
dp.Combustor_Eff=Burner.Eff;
dp.PR_volute_d=Outlet.PR;
dp.Combustor_PR=Burner.PR;
dp.HPS_Eff=HPS.Eff;
dp.LPS_Eff=LPS.Eff;
dp.heatvalue=heatvalue;
dp.PW=LPT.Power;
dp.SAS=data.SAS;
dp.LPSpeed=LPS.speed;
%% 燃烧室总压损失模型
[y,Rg]=tfd2gammarRg(HPC.T,0,0);
dp.Combustor.Ain=0.05;%Ain燃烧室入口截面积
dp.Combustor.c1=0.1;%c1，流动阻力损失系数
lam=lamb(HPC.W,dp.Combustor.Ain,Rg,y,HPC.P,HPC.T);%
Ma2=(2/(y+1)*lam*lam)/(1-(y-1)/(y+1)*lam*lam);%
PR_L=1-dp.Combustor.c1*lam*lam;

dp.Combustor.c2=0.45;%c2，热阻损失系数
dp.Combustor.Af=0.05;%Af火焰筒截面积
dp.Combustor.Ab=0.05;%
eH=dp.Combustor.c2*(Burner.T/HPC.T-1)*(dp.Combustor.Ab/dp.Combustor.Af)^2;
PR_H=1-eH*y/2*Ma2;

PR=PR_L*PR_H;%
dp.scalePRnum=Burner.PR/PR;

%% 机械损失模型
dp.Shaftloss1=HPT.Power*(1-HPS.Eff);
dp.Shaftloss2=LPT.Power/LPS.Eff*(1-LPS.Eff);
dp.shaftlossmethod =1;%机械损失计算方法，1为恒定机械效率
dp.bearingscale_on=1;%匹配开启
% %高压轴
N=HPS.speed;
bearing1.u_x=[6000,14000];
bearing1.u_y=[1.20908,0.0097313];
bearing1.Q1_x=[0,20000];
bearing1.Q1_y=[1,1];
bearing1.D1=100;
bearing1.type1=1;
bearing1.Q2_x=[0,20000];
bearing1.Q2_y=[1,1]; 
bearing1.D2=100;
bearing1.type2=2;
bearing1.Q3_x=[0,20000];
bearing1.Q3_y=[1,1]; 
bearing1.D3=100;
bearing1.type3=0;
bearing1.powerextract_x=[0,20000];
bearing1.powerextract_y=[0,0];

u=interp1g(bearing1.u_x,bearing1.u_y,N);
Q1=interp1g(bearing1.Q1_x,bearing1.Q1_y,N);
Q2=interp1g(bearing1.Q2_x,bearing1.Q2_y,N);
Q3=interp1g(bearing1.Q3_x,bearing1.Q3_y,N);
Powerloss1=Bearcal(N,bearing1.D1,u,Q1,bearing1.type1);
Powerloss2=Bearcal(N,bearing1.D2,u,Q2,bearing1.type2);
Powerloss3=Bearcal(N,bearing1.D3,u,Q3,bearing1.type3);
Powerloss4=interp1g(bearing1.powerextract_x,bearing1.powerextract_y,N);
Ploss=Powerloss1+Powerloss2+Powerloss3+Powerloss4;
dp.bearingscale_num1=dp.Shaftloss1/Ploss;
%动力轴
N=LPS.speed;
bearing2.u_x=[2000,8000];
bearing2.u_y=[1.20908,0.0097313];
bearing2.Q1_x=[0,20000];
bearing2.Q1_y=[1,1];
bearing2.D1=100;
bearing2.type1=1;
bearing2.Q2_x=[0,20000];
bearing2.Q2_y=[1,1]; 
bearing2.D2=100;
bearing2.type2=2;
bearing2.Q3_x=[0,20000];
bearing2.Q3_y=[1,1]; 
bearing2.D3=100;
bearing2.type3=0;
bearing2.powerextract_x=[0,20000];
bearing2.powerextract_y=[0,0];

u=interp1g(bearing2.u_x,bearing2.u_y,N);
Q1=interp1g(bearing2.Q1_x,bearing2.Q1_y,N);
Q2=interp1g(bearing2.Q2_x,bearing2.Q2_y,N);
Q3=interp1g(bearing2.Q3_x,bearing2.Q3_y,N);
Powerloss1=Bearcal(N,bearing2.D1,u,Q1,bearing2.type1);
Powerloss2=Bearcal(N,bearing2.D2,u,Q2,bearing2.type2);
Powerloss3=Bearcal(N,bearing2.D3,u,Q3,bearing2.type3);
Powerloss4=interp1g(bearing2.powerextract_x,bearing2.powerextract_y,N);
Ploss=Powerloss1+Powerloss2+Powerloss3+Powerloss4;
dp.bearingscale_num2=dp.Shaftloss2/Ploss;
dp.bearing1=bearing1;
dp.bearing2=bearing2;
%%
save([pwd,'/parameter/dp.mat'],'dp')
%% 构造迭代初值插值表x0_sheet,包括100%功率，80%功率，60%功率，40%功率，20%功率
creat_x0_sheet();
save([pwd,'/parameter/x0_sheet.mat'],'x0_sheet');