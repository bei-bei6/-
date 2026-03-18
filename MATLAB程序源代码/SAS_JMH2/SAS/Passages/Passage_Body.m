function [NErr,ed]=Passage_Body(x,data)
W=x; % 要求的流量

gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

Pt1=data.GasIn.Pt;
Tt1=data.GasIn.Tt;
Swirl1=data.GasIn.Swirl;%入口涡参数Swirl=气流旋转角速度*r^2
Ps2=data.Ps2;%true value
CaseOpt=data.CaseOpt;

d1=data.d1;
d2=data.d2;
r1=d1/2;
r2=d2/2;
rm=(r1+r2)/2;

D=data.D; % 当量直径Dh=4A/P
A=data.A;
A1=data.A1;
A2=data.A2;
AwI=data.AwI;
AwO=data.AwO;

[state1]=WTcalcState(W,Pt1,Tt1,A1,data.Cons); %入口截面流动参数
rhos1=state1.rhos;
V1=state1.V;
Ps1=state1.Ps;
Ma1=state1.Ma;
Ts1=state1.Ts;
%% 能量守恒方程
switch CaseOpt.htt % 计算换热温升
    case 0 % 给定热流
        deltaT_ht = (data.qI*AwI+data.qO*AwO)/(W*cp);
    case 1 % 给定壁温
        Re=W*D/(mu*A);
        data.TwI=800;%内壁面温度
        data.TwO=800;%外壁面温度
        if data.TwI>Tt1
            nI=0.4;
        else
            nI=0.3;
        end
        if data.TwO>Tt1
            nO=0.4;
        else
            nO=0.3;
        end
        NuI=0.023*Re^0.8*Pr^nI;%待修改
        NuO=0.023*Re^0.8*Pr^nO;
        hI=k/d1*NuI;%要修改
        hO=k/d2*NuO;%问题不大
        NTU=(hI*AwI+hO*AwO)/(W*cp);
        Tw_ave=(hI*AwI*data.TwI+hO*AwO*data.TwO)/(hI*AwI+hO*AwO);
        deltaT_ht = (Tw_ave-(Tw_ave-Tt1)*exp(-NTU))-Tt1; % Heat Transfer
end
%
%     Text=293.15;%环境温度 待定
%     if data.RESO==0 %情况1：外壁面静止
%         alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;%alpha_v体积变化系数，对于理想气体即等于绝对温度的倒数
%         Gr=abs(D^3*rho^2*alpha_v*(Ts-Text)/mu^2);
%         Pr=cp*mu/k;
%         if Gr*Pr>1e-5 && Gr*Pr<1e-3
%             a=0.71;
%             m=0.04;
%         elseif Gr*Pr>1e-3 && Gr*Pr<1
%             a=1.09;
%             m=0.1;
%         elseif Gr*Pr>1 && Gr*Pr<1e4
%             a=1.09;
%             m=0.2;
%         elseif Gr*Pr>1e4 && Gr*Pr<1e9
%             a=0.53;
%             m=0.25;
%         elseif Gr*Pr>1e9
%             a=0.13;
%             m=0.333;
%         end
%         Nu=a*(Gr*Pr)^m;
%         h=Nu*k/D;
%         q=h*(Two-Ts);
%         P=pi*D;
%         omega=q*P;
%     else %情况2：外壁面旋转
%         Re_ext=rho*pi*w2*data.d2^2/mu;
%         Pr=cp*mu/k;
%         alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
%         Gr=abs(rho^2*alpha_v*g*(Two-Text)*D^3/mu^2);
%         Nu=0.11*(0.5*Re_ext^2+Gr*Pr)^0.35;
%         h=Nu*k/D;
%         q=h*(Two-Ts);
%         P=pi*D;
%         omega=q*P;
%     end
%% 计算风阻温升
%推进计算旋流因子,从而计算风阻导致的流体总温变化
omegaI=2*pi*(data.RESI/60); % 内壁面转速,rad/s
omegaO=2*pi*(data.RESO/60); % 外壁面转速,rad/s
omega_ref=max([omegaI,omegaO]); % 参考转子转速,rad/s
Sf1=Swirl1/(omega_ref*rm^2); % 入口旋转比
delta_x = data.L/data.N;
M_rotor = 0;
if Sf1>1
    Tt2 = Tt1 + deltaT_ht;
    Sf2 = Sf1;
else
    if omegaI == 0 && omegaO ==0 %静止环形通道无风阻温升
        Sf2 = Sf1;
        Swirl2 = Swirl1;
    elseif omegaI == 0 && omegaO ~=0 % 内壁面为静柱面，外壁面为转柱面
        RewI=rhos1*omega_ref*(d1/2)^2/mu;
        RewO=rhos1*omega_ref*(d2/2)^2/mu; % 旋转雷诺数
        syms Sf2;
        cf_I=0.063*(abs(Sf2))^1.87*RewI^-0.2; %内壁静柱面剪切系数
        M_I=cf_I*1/2*rhos1*Sf2^2*omega_ref^2*2*pi*(d1/2)^4*delta_x; % 内壁静柱面转矩
        cf_O=0.042*(1-Sf2)^1.35*RewO^-0.2; % 外壁转柱面剪切系数
        M_O=cf_O*1/2*rhos1*(1-Sf2)^2*omegaO^2*2*pi*r2^4*delta_x;
        eq1=M_O-M_I;
        eq2=W*omega_ref*((d1+d2)/2)^2*(Sf2-Sf(i));
        Sf2=double(vpasolve(eq1-eq2));
        % 代值
        M_rotor = M_rotor + M_O;
        M_rotor=eval(M_rotor);
    elseif omegaI ~= 0 && omegaO ==0 % 内壁面为转柱面，外壁面为静柱面
        RewI=rhos1*omega_ref*(d1/2)^2/mu;
        RewO=rhos1*omega_ref*(d2/2)^2/mu;
        syms Sf2;
        cf_I=0.042*(1-Sf2)^1.35*RewI^-0.2; % 内壁转柱面剪切系数
        M_I=cf_I*1/2*rhos1*(1-Sf2)^2*omegaI^2*2*pi*r1^4*delta_x; % 内壁转柱面转矩
        cf_O=0.063*(abs(Sf2))^1.87*RewO^-0.2; %外壁静柱面剪切系数
        M_O=cf_O*1/2*rhos1*Sf2^2*omega_ref^2*2*pi*(d2/2)^4*delta_x; % 外壁静柱面转矩
        eq1=M_I-M_O;
        eq2=W*omega_ref*((d1+d2)/2)^2*(Sf2-Sf(i));
        Sf2=double(vpasolve(eq1-eq2));
        % 代值
        M_rotor = M_rotor + M_I;
        M_rotor=eval(M_rotor);
    else  % 内外壁面均为转柱面
        RewI=rhos1*omega_ref*abs(omegaI/omega_ref)*(d1/2)^2/mu;
        RewO=rhos1*omega_ref*abs(omegaO/omega_ref)*(d2/2)^2/mu;
        syms Sf2;
        cf_I=0.042*(1-Sf2)^1.35*RewI^-0.2; % 内壁转柱面剪切系数
        M_I=cf_I*1/2*rhos1*(1-Sf2)^2*omegaI^2*2*pi*r1^4*delta_x; % 内壁转柱面转矩
        cf_O=0.042*(1-Sf2)^1.35*RewO^-0.2; % 外壁转柱面剪切系数
        M_O=cf_O*1/2*rhos1*(1-Sf2)^2*omegaO^2*2*pi*r2^4*delta_x;
        eq1=M_O+M_I;
        eq2=W*omega_ref*rm^2*(Sf2-Sf1);
        Sf2=double(vpasolve(eq1-eq2));%控制体出口旋转比
        % 代值
        M_rotor = M_rotor + M_O + M_I;
        M_rotor=eval(M_rotor);
    end
    Q_windage=M_rotor*omega_ref; % 风阻输入热
    deltaT_windage = Q_windage/(W*cp); % 风阻温升
    Tt2 = Tt1 + deltaT_ht + deltaT_windage;% 出口总温
end
%% 出口截面马赫数及流动参数
[state2]=WScalcState(W,data.Ps2,Tt2,A2,data.Cons); %出口截面流动参数
rhos2=state2.rhos;
V2=state2.V;
Ma2=state2.Ma;
Ts2=state2.Ts;
Pt2=state2.Pt;
%% 动量方程
ave_rhos=(rhos1+rhos2)/2;
ave_V=(V1+V2)/2;
ave_A=A;
Re=W*D/(mu*A);
if omegaI==0 && omegaO==0% stationary passages 情况1：内外壁面均静止
    if Re<=2000 % 层流
        r_ratio=d1/d2;
        if (r_ratio<= 0)
            Cf=64; % Laminar flow coefficient
        elseif r_ratio >= 0.999
            Cf=96;
        else
            Cf=(64*(1-r_ratio)^2)/(1+ r_ratio^2+(1- r_ratio^2)/log(r_ratio));%【】
        end
        f=Cf/Re;
        f=2*f;
    elseif Re>=4000 % 湍流
        f=0.25/(log10(data.roughness/(3.7*D)+5.74/Re^0.9))^2;
        f=2*f;
    else % 过渡流
        if (r_ratio<= 0)
            Cf=64; % Laminar flow coefficient
        elseif r_ratio >= 0.999
            Cf=96;
        else
            Cf=(64*(1-r_ratio)^2)/(1+ r_ratio^2+(1- r_ratio^2)/log(r_ratio));%【？】
        end
        fl=Cf/Re;
        ft=0.25/(log10(data.roughness/(3.7*D)+5.74/Re^0.9))^2;
        f=(fl+ft)/2;
        f=2*f;
    end
else % 情况2：有且只有一个壁面旋转
    f0=0.25/(log10(data.roughness/(3.7*D)+5.74/Re^0.9))^2;%达西摩擦因子（3-14）
    if omegaI~=0 && omegaO==0 % 内壁面旋转
        Rew=ave_rhos*abs(omega_ref)*d1*(d1-d2)/(2*mu);
        f_f0=(1+(7/8)^2*(Rew/(2*Re))^2)^0.38;
        f=f_f0*f0;  % 考虑旋转效应修正的达西摩擦因子
    elseif omegaI==0 && omegaO~=0% 外壁面旋转
        Rew=ave_rhos*abs(omega_ref*(d2^2-d1^2))/(4*mu);
        f_f0=RAP_f0Calc(Rew/Re,d1/d2);%外壁旋转摩擦修正系数【和论文对不上？】
        f=f_f0*f0;
    else %情况3：两壁面旋转
        Rew1=ave_rhos*abs(omegaI)*d1*(d1-d2)/(2*mu);
        f_f01=(1+(7/8)^2*(Rew1/(2*Re))^2)^0.38;
        f1=f_f01*f0;
        Rew2=ave_rhos*abs(omegaO*(d2^2-d1^2))/(4*mu);
        f_f02=RAP_f0Calc(Rew2/Re,d1/d2);
        f2=f_f02*f0;
        f=abs(f1+f2);
    end
end
deltaP_f = f*data.L/D*0.5*ave_rhos*V2^2; % 摩擦引起的静压变化
deltaP_mom = W*(V2-V1)/ave_A; % 动量变化引起的静压变化
Ps2 = Ps1 - deltaP_f + deltaP_mom; % Ps2'

NErr=(Ps2-data.Ps2)/data.Ps2;

ed.Pt1=Pt1;
ed.Ps1=Ps1;
ed.Tt1=Tt1;
ed.Ts1=Ts1;
ed.Pt2=Pt2;
ed.Ps2=Ps2;
ed.Tt2=Tt2;
ed.Ts2=Ts2;
ed.Ma=[Ma1 Ma2];
ed.Sf2=Sf2;
ed.Swirl2=Sf2*(omega_ref*(rm^2));
flowdirection=cp/R*log(Ts2/Ts1)-log(Ps2/Ps1);
%flowdirection=cp/R*log(Tt2/Tt1)-log(Pt2/Pt1);
end