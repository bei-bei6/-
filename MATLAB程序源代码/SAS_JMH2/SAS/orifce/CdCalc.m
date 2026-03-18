function Cd=CdCalc(Re,rf,D,L,Pt1,Psout,Vx,V_phi,beta,theta0) %流量系数Cd计算（需要：入口雷诺数Re、入口倒圆的圆角半径、孔直径、孔长、孔入口总压、孔出口静压、入口绝对速度、入口圆周速度、倾角）【未考虑进口倒角形式的修正】
Cd_Re=0.5885+372/Re; %考虑Re影响时，锐边短孔的Cd修正【缺少理想喷嘴（长孔）公式】
%
g1=0.008+0.992*exp(-5.5*(rf/D)-3.5*(rf/D)^2);%rf为圆角半径，D为孔直径【有误：0.993应为0.992】
Cd_r=1-g1*(1-Cd_Re);%考虑进口倒圆的Cd修正【缺少考虑进口倒角时的Cd修正】
%
g3=(1+1.3*exp(-1.606*(L/D)^2))*(0.435+0.021*L/D);%L为孔长度
Cd_r_L=1-g3*(1-Cd_r);%考虑孔长度的Cd修正
%以上修正仅适用于不可压缩流动
%
PR=Pt1/Psout;%压比=孔入口总压/孔出口静压
C1_pi=0.8454+0.3797*exp(-0.9083*PR);
C2_pi=6.6687*exp(0.4619*PR-2.367*PR^0.5);
g4=Cd_r_L/0.263*(C1_pi-C2_pi)+C2_pi; % g4
Cd_r_L_pi=1-g4*(1-Cd_r_L);%可压缩流动时的Cd修正
%
C1_pp=0.04717*beta-0.5e-3*beta^2;
C2_pp=-1+2.88*Cd_r_L_pi-1.877*Cd_r_L_pi^2;
Cd_r_L_pi_pp=Cd_r_L_pi+C1_pp*C2_pp;%【这是考虑了什么的修正？】

% 上面为普通孔，下面计算旋转孔
% 计算 攻角theta
Cid=Vx; % Cid为绝对速度
U=V_phi; % U为圆周速度
theta=atan(U/Cid)/pi*180-theta0;% 攻角theta；beta为倾角；

C3=-3.638e-4*theta^2;%锐边孔的C3
if rf==0 %进口圆角半径为0，即进口无倒角（锐边孔）
   Cd_r_L_pi_pp_i=Cd_r_L_pi_pp+C3; 
else
    C4=-3.061e-3*exp(0.1239*theta);
    Cd_r_L_pi_pp_i=Cd_r_L_pi_pp+4*(rf/D-0.25)*(C4-C3)+C4;%进口倒圆【有误：还应加上C_rd】
end
%
Cd=Cd_r_L_pi_pp_i;
end