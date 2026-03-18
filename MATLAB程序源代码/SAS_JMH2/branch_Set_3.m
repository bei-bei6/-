function SAS=branch_Set_3(BC)
Cons=Cons_set();
%% 压力源
% 支路3 引气
SAS.SPSI1.Pt=BC.Pt1;
SAS.SPSI1.Tt=BC.Tt1;
SAS.SPSI1.Swirl=0;
%% 背压源
% 支路3背压
SAS.Pamb1=BC.Pamb1;
SAS.Pamb2=BC.Pamb2;
%
SAS.HP_Shaft=BC.HP_Shaft;
SAS.LP_Shaft=BC.LP_Shaft;
%% 支路3
% 管
SAS.Pipe3_1.Num=4;
SAS.Pipe3_1.d=26.8e-3;
SAS.Pipe3_1.L=600e-3;
SAS.Pipe3_1.roughness=0.001;
SAS.Pipe3_1.N=5;
SAS.Pipe3_1.theta=0;
SAS.Pipe3_1.Tw=273.15*ones(1,SAS.Pipe3_1.N); %T44
SAS.Pipe3_1.ST='incompressible';
SAS.Pipe3_1.type=0; %Adiabatic Flow=0,Full Heat Transfer =1;
SAS.Pipe3_1.Cons=Cons;
% 低压涡轮导叶
SAS.LPT_Vane3_1.Num=12;
SAS.LPT_Vane3_1.L=65e-3;
SAS.LPT_Vane3_1.theta=0;
SAS.LPT_Vane3_1.d=25e-3/2;
SAS.LPT_Vane3_1.roughness=0.0010*SAS.LPT_Vane3_1.d;
SAS.LPT_Vane3_1.RES=0;
SAS.LPT_Vane3_1.N=5;
SAS.LPT_Vane3_1.Tw=0*ones(1,SAS.LPT_Vane3_1.N);
SAS.LPT_Vane3_1.ST='compressible';
SAS.LPT_Vane3_1.type=0;%0='Adiabatic';
SAS.LPT_Vane3_1.Cons=Cons;
% 冷却模型几何参数
SAS.LPT_Vane3_1.Alet=pi*(SAS.LPT_Vane3_1.d/2)^2;
SAS.LPT_Vane3_1.Ag=2*pi*(SAS.LPT_Vane3_1.d/2)*SAS.LPT_Vane3_1.L;
SAS.LPT_Vane3_1.Ac=pi*(SAS.LPT_Vane3_1.d/2)^2;
% 传热模型
SAS.LPT_Vane3_1.eta_c=0.6;
SAS.LPT_Vane3_1.eta_f=0.7;
SAS.LPT_Vane3_1.Bi_tbc=1;
SAS.LPT_Vane3_1.Bi_bw=1;
SAS.LPT_Vane3_1.delta_tbc=SAS.LPT_Vane3_1.Bi_tbc*1.8/10000;
SAS.LPT_Vane3_1.delta_bw=SAS.LPT_Vane3_1.Bi_bw*13/10000;
SAS.LPT_Vane3_1.k_tbc=1.8;
SAS.LPT_Vane3_1.k_bw=13;
%
SAS.LPT_Vane.Trans1.d1=32e-3/2; %突缩
SAS.LPT_Vane.Trans1.d2=4.4e-3;
SAS.LPT_Vane.Trans1.L=1e-3;
SAS.LPT_Vane.Trans1.Num=60;
SAS.LPT_Vane.Trans1.Cons=Cons;
%
SAS.rimseal3_1.NT=2;
SAS.rimseal3_1.Rsi=278e-3;%shaft radius
SAS.rimseal3_1.Cri=0.4e-3; %radial Clearance 
SAS.rimseal3_1.Li=2e-3; %Labyrith seal  Pitch
SAS.rimseal3_1.ti=0.5e-3; %Labyrith seal tooth Tip length
SAS.rimseal3_1.Bi=0.2e-3;;%Labyrith seal tooth height
SAS.rimseal3_1.RS=SAS.LP_Shaft;%rpm
SAS.rimseal3_1.Pos='Rotor';
SAS.rimseal3_1.Method='explicit';%'explicit';
SAS.rimseal3_1.Cons=Cons;

% 喷嘴
SAS.Hole3_1.Num=26;
SAS.Hole3_1.D=3.5e-3;
SAS.Hole3_1.rf=0.09e-3; %孔入口倒圆的圆角半径
SAS.Hole3_1.L=0.01; %管长
SAS.Hole3_1.beta=90/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.Hole3_1.theta0=0; 
SAS.Hole3_1.Cons=Cons;
% 喷嘴
SAS.Hole3_2.Num=28;
SAS.Hole3_2.D=3.38e-3;
SAS.Hole3_2.rf=0.09e-3; %孔入口倒圆的圆角半径
SAS.Hole3_2.L=0.01; %管长
SAS.Hole3_2.beta=90/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.Hole3_2.theta0=0; 
SAS.Hole3_2.Cons=Cons;
end