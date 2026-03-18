function [SAS]=branch_Set_1(BC)
Cons=Cons_set();
%% 压力源
% 支路1 引气
SAS.SPSI1.Pt=BC.Pt1;
SAS.SPSI1.Tt=BC.Tt1;
SAS.SPSI1.Swirl=0;
%% 背压源
% 支路1背压
SAS.Pamb1=BC.Pamb1;
%% 高低压转速
%{
SAS.HP_Shaft=BC.HP_Shaft;
SAS.LP_Shaft=BC.LP_Shaft;
%}
%% 支路1
% 静止孔1
SAS.Hole1.Num=30;
SAS.Hole1.D=10e-3;
SAS.Hole1.rf=1e-3; %孔入口倒圆的圆角半径
SAS.Hole1.L=6e-3; %管长
SAS.Hole1.beta=90/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.Hole1.theta0=0; 
SAS.Hole1.Cons=Cons;

% 静止孔2
SAS.Hole2.Num=8;
SAS.Hole2.D=28e-3;
SAS.Hole2.rf=1e-3; %孔入口倒圆的圆角半径
SAS.Hole2.L=3e-3; %管长
SAS.Hole2.beta=90/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.Hole2.Cons=Cons;
SAS.Hole2.theta0=0; 

% 高压涡轮导叶
SAS.HPT_Vane1.Num=44;
SAS.HPT_Vane1.L=65e-3;
SAS.HPT_Vane1.theta=0;
SAS.HPT_Vane1.d=18e-3/2;
SAS.HPT_Vane1.roughness=0.0010*SAS.HPT_Vane1.d;
SAS.HPT_Vane1.RES=0;
SAS.HPT_Vane1.N=5;
SAS.HPT_Vane1.Tw=0*ones(1,SAS.HPT_Vane1.N);
SAS.HPT_Vane1.ST='compressible';
SAS.HPT_Vane1.type=0;%0='Adiabatic';
SAS.HPT_Vane1.Cons=Cons;
% 冷却模型几何参数
SAS.HPT_Vane1.Alet=pi*(SAS.HPT_Vane1.d/2)^2;
SAS.HPT_Vane1.Ag=2*pi*(SAS.HPT_Vane1.d/2)*SAS.HPT_Vane1.L;
SAS.HPT_Vane1.Ath=pi*(SAS.HPT_Vane1.d/2)^2;
% 传热模型
SAS.HPT_Vane1.eta_c=0.6;
SAS.HPT_Vane1.eta_f=0.7;
SAS.HPT_Vane1.hg=1420;
SAS.HPT_Vane1.Bi_tbc=1;
SAS.HPT_Vane1.Bi_bw=1;
SAS.HPT_Vane1.delta_tbc=SAS.HPT_Vane1.Bi_tbc*1.8/10000;
SAS.HPT_Vane1.delta_bw=SAS.HPT_Vane1.Bi_bw*13/10000;
SAS.HPT_Vane1.k_tbc=1.8;
SAS.HPT_Vane1.k_bw=13;
%
SAS.HPT_Vane.Trans1.d1=35e-3/2; %突缩
SAS.HPT_Vane.Trans1.d2=8e-3;
SAS.HPT_Vane.Trans1.L=1e-3;
SAS.HPT_Vane.Trans1.Num=48;
SAS.HPT_Vane.Trans1.Cons=Cons;
end