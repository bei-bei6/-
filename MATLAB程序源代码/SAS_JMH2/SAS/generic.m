function GasOut=generic(GasIn,Ps,data)
%该程序可以计算通用单元的可压缩腔流动
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

boundary=data.boundary;
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;
Swirl1=GasIn.Swirl;%入口涡参数Swirl=气流旋转角速度*r^2
W=GasIn.W;

J=length(W);%进口边界总数J
K=length(boundary.type);%壁面总数
W_mix=sum(GasIn.W); % 混合流量
omega=data.boundary.RES*2*pi/60; % 各转子角速度, rad/s
omega_ref=max(abs(boundary.RES))*2*pi/60; % 参考转子角速度,rad/s
Dh=2*data.G;
%% 各入口静参数
[state1]=WTcalcState(W,Pt1,Tt1,data.A_in,data.Cons);
rhos1=sum(W.*state1.rhos)/W_mix; %入口平均密度（质量加权平均）
V1=sum(W.*state1.V)/W_mix;
Ps1=sum(W.*state1.Ps)/W_mix;
Ma1=sum(W.*state1.Ma)/W_mix;
Ts1=sum(W.*state1.Ts)/W_mix;
Tt1=sum(W.*Tt1)/W_mix;
%% 角动量守恒方程：计算出口旋转比Sf_2
Beta=omega/omega_ref; %正则化转子角速度
M_rotor=0; M_stator=0;
syms Sf2;
Q_windage=0;
for i=1:K %计算壁面的摩擦力矩
    M_r_disk=0;M_r_cylinder=0;M_r_cone=0;M_s_disk=0;M_s_cylinder=0;M_s_cone=0;
    switch boundary.type(i)  %壁面结构类型：1：disk；2：cylinder；3：cone；
        case 1 %disk
            if boundary.RES(i) ~= 0 % 转径面
                Rew=rhos1*abs(Beta(i))*omega_ref*data.PosH^2/mu;%旋转雷诺数
                cf_rotor=0.07*sign(Beta(i)-Sf2)*(abs(Beta(i)-Sf2))^-0.65*(abs(Beta(i)))^0.65*Rew^-0.2; % 转子局部剪切系数
                M_r_disk=cf_rotor*1/2*rhos1*(Beta(i)-Sf2)^2*omega_ref^2*2/5*pi*(data.PosH^5-data.PosL^5);
            else % 静径面
                Rew=rhos1*omega_ref*data.PosH^2/mu;
                cf_stator=0.105*(Sf2)^-0.13*Rew^-0.2;
                M_s_disk=cf_stator*1/2*rhos1*Sf2^2*omega_ref^2*2/5*pi*(data.PosH^5-data.PosL^5);
            end
        case 2 % cylinder
            if omega(i) ~= 0 % 转柱面（注意Rew内的特征尺寸选取）
                Rew=rhos1*abs(Beta(i))*omega_ref*data.boundary.Rh^2/mu;
                cf_rotor=0.042*sign(Beta(i)-Sf2)*(abs(Beta(i)-Sf2))^-0.65*(abs(Beta(i)))^0.65*Rew^-0.2;
                M_r_cylinder=cf_rotor*1/2*rhos1*(Beta(i)-Sf2)^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
            else % 静柱面
                Rew=rhos1*omega_ref*data.boundary.Rh^2/mu;
                cf_stator=0.063*(abs(Sf2))^1.87*Rew^-0.2;
                M_s_cylinder=cf_stator*1/2*rhos1*Sf2^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
            end
        case 3 % cone
            if omega(i) ~= 0 % 转锥面(Rew和cf同转径面）
                Rew=rhos1*abs(Beta(i))*omega_ref*data.PosH^2/mu;
                cf_rotor=0.07*sign(Beta(i)-Sf2)*(abs(Beta(i)-Sf2))^-0.65*(abs(Beta(i)))^0.65*Rew^-0.2;
                M_r_cone=cf_rotor*1/2*rhos1*(Beta(i)-Sf2)^2*omega_ref^2*2/5*pi*(data.PosH^5-data.PosL^5)/sin(theta(i));
            else % 静锥面(Rew和cf同静径面）
                Rew=rhos1*omega_ref*data.PosH^2/mu;
                cf_stator=0.105*(abs(Sf2))^-0.13*Rew^-0.2;
                M_s_cone=cf_stator*1/2*rhos1*Sf2^2*omega_ref^2*2/5*pi*(data.PosH^5-data.PosL^5)/sin(theta(i));
            end
    end%若有螺栓，可在定义盘几何的函数里标记有螺栓的控制体flag=1，再加上螺栓的力矩
    M_rotor=M_rotor+M_r_disk+M_r_cylinder+M_r_cone;
    M_stator=M_stator+M_s_disk+M_s_cylinder+M_s_cone;
end
Sf1=(Swirl1./data.r_in^2)./omega_ref;% 入口旋转比
eq1=M_rotor-M_stator;
if omega_ref ~= 0
    eq2=(W_mix*data.r_m^2*Sf2-sum(W.*data.r_in^2.*Sf1))*omega_ref;
else
    eq2=W_mix*data.r_m^2*Sf2*omega_ref-sum(W.*Swirl1);
end
Sf2=double(vpasolve(eq1-eq2));
M_rotor=eval(M_rotor);
%% 能量方程：计算出口总温
% 总输入热：风阻和对流换热输入的热量
Q_windage=M_rotor*omega_ref; % 风阻输入热
A=pi*(data.PosH^2-data.PosL^2); % 控制体圆环面积
% 计算换热温升
Q_ht = 0; % heat transfer
for i=1:K
    if ~isnan(boundary.q(i))
        Q_ht = Q_ht + boundary.q(i)*A;
    elseif ~isnan(boundary.Tw(i))
        % Re=W*D/(mu*A);
        if boundary.RES(i) ~= 0 % 旋转壁面
            Rew = rhos1*omega_ref*data.PosH^2/mu;% 旋转雷诺数
            Nu=0.0545/3.14*(data.G/2)^0.1*Rew^0.8;% Nu可以替换不同的经验公式
            h = Nu*k/data.r_m;%对流换热系数h，控制体中心半径 Rm=(R1+R2)/2
            Q_ht = Q_ht + h*A*(boundary.Tw(i)-Tt1);
        else % 静止壁面
            Re=abs(rhos1*V1*Dh/mu); % Dh=4A/P=2G
            if Re < 5e5 % 层流
                Nu=0.664*Re^(1/2)*Pr^(1/3);
            else % 湍流
                Nu=0.037*Re^(4/5)*Pr^(1/3);
            end
            h = Nu*k/(data.PosH-data.PosL); % 特征长度为控制体高
            Q_ht = Q_ht + h*A*(boundary.Tw(i)-Tt1);
        end
    end
end
Tot_Qcell = Q_windage + Q_ht;
deltaT_windage=Q_windage/(W_mix*cp);
deltaT_ht=Q_ht/(W_mix*cp);
deltaT=deltaT_windage+deltaT_ht;
Tt2 = Tt1 + Tot_Qcell/(W_mix*cp);% 出口总温
%% 动量方程
%

Rer=rhos1*V1*Dh/mu; % 径向雷诺数
Rew=rhos1*omega_ref*data.PosH^2/mu;
roughness=mean(boundary.roughness);
if Rer<4000
    f_Darch=64/Rew;
elseif Rer>=4000
    f_Darch=0.25/(log10(roughness/(3.7*Dh)+5.74/Rew^0.9))^2;
else
    fl=64/Rer;
    ft=0.25/(log10(roughness/(3.7*Dh)+5.74/Rew^0.9))^2;
    por=(Rew-2000)/2000;
    f_Darch=por*ft+(1-por)*fl;
end
KK=f_Darch*(data.PosH-data.PosL)/Dh;% Loss coefficient
%Pt2=Pt1+rhos1*(Sf2*omega_ref)^2*abs(data.PosH^2-data.PosL^2)/2-KK*W_mix^2/(2*rhos1*data.A_in);
Pt2=Pt1+rhos1*(Sf2*omega_ref)^2*abs(data.PosH^2-data.PosL^2)/2; % 涡旋压升造成总压变化

[state2]=WTcalcState(W_mix,Pt2,Tt2,data.A_out,data.Cons);%出口截面流动参数
rhos2=state2.rhos;
Ma2=state2.Ma;
V2=state2.V;
Ts2=state2.Ts;
%V2=sqrt(Vr2^2+(Sf2*omega_ref*data.r_out)^2);
Ps2=state2.Ps;
%% 输出参数
GasOut.W=W_mix;
GasOut.Ma2=Ma2;
GasOut.Pt2=Pt2;
GasOut.Ps2=Ps2;
GasOut.Tt2=Tt2;
GasOut.Ts2=Ts2;
GasOut.Sf2=Sf2;%通过角动量守恒方程计算得
GasOut.rhos2=rhos2;
GasOut.Swirl2=Sf2*omega_ref*data.r_out^2;
GasOut.V2=V2;
end