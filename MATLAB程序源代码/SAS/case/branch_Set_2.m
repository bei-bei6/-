function [SAS]=branch_Set_2(BC)
Cons=Cons_set();
%% 压力源
% 支路2 引气
SAS.SPSI1.Pt=BC.Pt1;
SAS.SPSI1.Tt=BC.Tt1;
SAS.SPSI1.Swirl=0;
%% 背压源
% 支路2背压
SAS.Pamb1=BC.Pamb1;
%% 支路2
% 预旋喷嘴
SAS.Hole1.Num=68;
SAS.Hole1.D=6.6e-3;
SAS.Hole1.rf=0.105e-3; %孔入口倒圆的圆角半径
SAS.Hole1.L=0.0118; %管长
SAS.Hole1.beta=45/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.Hole1.theta0=0; 
SAS.Hole1.Cons=Cons;

% 接受孔
SAS.rechol.Num=52;
SAS.rechol.D=6.4e-3;
SAS.rechol.rf=0.1e-3; %孔入口倒圆的圆角半径
SAS.rechol.L=0.0045; %管长
SAS.rechol.r1=0.1937; %入口截面距离旋转轴的径向位置
SAS.rechol.roughness=0.5e-05; %粗糙度
SAS.rechol.beta=90/180*pi; %孔倾角（孔轴线与开孔壁面的夹角）
SAS.rechol.theta0=0; 
SAS.rechol.RES=BC.HP_Shaft;
SAS.rechol.Cons=Cons;

% 叶片冷却
SAS.Blade.Num=24;
SAS.Blade.L=0.0468;
SAS.Blade.theta=0;
SAS.Blade.d=0.025/3;
SAS.Blade.roughness=0.0050*SAS.Blade.d;
SAS.Blade.RES=0;
SAS.Blade.N=3;
SAS.Blade.Tw=0*ones(1,SAS.Blade.N);
SAS.Blade.ST='compressible';
SAS.Blade.type=0;%0='Adiabatic';
SAS.Blade.Cons=Cons_set();
% 冷却模型几何参数
SAS.Blade.Alet=pi*(SAS.Blade.d/2)^2;
SAS.Blade.Ag=SAS.Blade.Num*2*pi*(SAS.Blade.d/2)*SAS.Blade.L;
SAS.Blade.Ath=0.05;
% 传热模型
SAS.Blade.eta_c=0.6;
SAS.Blade.eta_f=0.7;
SAS.Blade.hg=1420;
SAS.Blade.delta_tbc=1.8e-4;
SAS.Blade.delta_bw=0.0013;
SAS.Blade.k_tbc=1.8;
SAS.Blade.k_bw=13;

end