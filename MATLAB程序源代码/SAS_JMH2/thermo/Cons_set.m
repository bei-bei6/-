function Cons=Cons_set()
Cons.C_PSTD=101325;%海平面大气压
Cons.C_TSTD=288.15;%海平面静温
Cons.gamma =1.40;%理想气体双原子气体（空气）比热容比
Cons.gammag =1.33;%燃气的比热容比
Cons.R=287.05;%空气的气体常数Rg=287.05J/(kg*K)
Cons.cp=1004;
Cons.cpg=1004;
Cons.cv=717; %空气的定容比热容 J/(kg*K)
Cons.mo=0.0289634;%空气的摩尔质量kg/mol
Cons.g=-9.807;% 重力加速度
Cons.mu=1.784e-5;%空气的动力粘度
Cons.k=0.024;%空气的导热系数
Cons.Pr=Cons.cp*Cons.mu/Cons.k;
end