function [NErr,ed]=generic_Body(x,data) % W
W=x; % 要求的流量
%%
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

Pt1=data.GasIn.Pt;
Tt1=data.GasIn.Tt;
Swirl1=data.GasIn.Swirl;%入口涡参数Swirl=气流旋转角速度*r^2
Ps2=data.Ps2;

boundary=data.boundary;

PosL=data.Geo.PosL; % 低位半径
PosH=data.Geo.PosH; % 高位半径
AI=data.AI; % 入口面积
AO=data.AO; % 出口面积
G=data.Geo.G;% max(x)-min(x) 间隙, m
N=data.Geo.N;
face=data.Geo.face;
theta=data.Geo.theta;
y_k=data.Geo.y_k;
wall_type=data.boundary.wall_type;%壁面结构类型：1：disk；2：cylinder；3：cone；
Rin=data.Rin; % 入口半径
Rout=data.Rout; % 出口半径
omega=data.boundary.RES*2*pi/60; % 各转子角速度, rad/s
omega_ref=data.omega_ref; % 参考转子角速度, rad/s
Sf1=(Swirl1/Rin^2)/omega_ref; % 入口旋转比

l_max=size(face,2); % 最多控制体面数


R1=y_k(i); % 控制体入口半径
R2=y_k(i+1); % 控制体出口半径
Rm=(R1+R2)/2; % 控制体中心半径Rm
%     dr=abs(R2-R1); % p12=distance_p(face{i,1},face{i,2});
%     G_L=distance_p(face{i,2},face{i,3}); % 控制体低位间隙, m
%     G_H=distance_p(face{i,end},face{i,1}); % 控制体高位间隙, m
l=length(cell2mat(face(i,:)))/2; % 控制体面数
if data.direction == 1 % data.direction:1从下至上，-1为从上至下
    A1=2*pi*R1*G; % 控制体进口面积
    A2=2*pi*R2*G; % 控制体出口面积
elseif data.direction == -1
    A1=2*pi*R1*G;
    A2=2*pi*R2*G;
end
if i==1
    [state1]=WTcalcState(W,Pt1,Tt1,A1,data.Cons); %控制体入口截面流动参数
    rhos1=state1.rhos;
    Vr1=state1.V;%径向速度Vr
    Ps1=state1.Ps;
    Ma1=state1.Ma;
    Ts1=state1.Ts;
    inlet=state1;
elseif i~=1 % 各控制体入口参数
    Pt1=Pt2;
    Tt1=Tt2;
    Sf1=Sf_k; % 上一个控制体k的旋转比
    [state1]=WTcalcState(W,Pt1,Tt1,A1,data.Cons); %控制体入口截面流动参数
    rhos1=state1.rhos;
    Vr1=state1.V;%径向速度Vr
    Ps1=state1.Ps;
end
%% 角动量守恒方程：计算每个控制体的旋转比Sf_k
Beta=omega/omega_ref; %正则化转子角速度
M_rotor=0; M_stator=0;
syms Sf_k;
Q_windage=0;
if omega_ref ~=0
    for j=1:l
        M_r_disk=0;M_r_cylinder=0;M_r_cone=0;M_s_disk=0;M_s_cylinder=0;M_s_cone=0;
        if ~isnan(wall_type(j))
            switch wall_type(j) %计算腔任意表面的摩擦力矩 %壁面结构类型：1：disk；2：cylinder；3：cone；
                case 1 %disk
                    if omega(j) ~= 0 % 转径面
                        Rew=rhos1*abs(Beta(j))*omega_ref*PosH^2/mu;%旋转雷诺数
                        cf_rotor=0.07*sign(Beta(j)-Sf_k)*(abs(Beta(j)-Sf_k))^-0.65*(abs(Beta(j)))^0.65*Rew^-0.2; % 转子局部剪切系数
                        M_r_disk=cf_rotor*1/2*rhos1*(Beta(j)-Sf_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                    else % 静径面
                        Rew=rhos1*omega_ref*PosH^2/mu;
                        cf_stator=0.105*(Sf_k)^-0.13*Rew^-0.2;
                        M_s_disk=cf_stator*1/2*rhos1*Sf_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                    end
                case 2 % cylinder
                    if omega(j) ~= 0 % 转柱面（注意Rew内的特征尺寸选取）
                        Rew=rhos1*abs(Beta(j))*omega_ref*data.boundary.Rh^2/mu;
                        cf_rotor=0.042*sign(Beta(j)-Sf_k)*(abs(Beta(j)-Sf_k))^-0.65*(abs(Beta(j)))^0.65*Rew^-0.2;
                        M_r_cylinder=cf_rotor*1/2*rhos1*(Beta(j)-Sf_k)^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                    else % 静柱面
                        Rew=rhos1*omega_ref*data.boundary.Rh^2/mu;
                        cf_stator=0.063*(abs(Sf_k))^1.87*Rew^-0.2;
                        M_s_cylinder=cf_stator*1/2*rhos1*Sf_k^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                    end
                case 3 % cone
                    if omega(j) ~= 0 % 转锥面(Rew和cf同转径面）
                        Rew=rhos1*abs(Beta(j))*omega_ref*PosH^2/mu;
                        cf_rotor=0.07*sign(Beta(j)-Sf_k)*(abs(Beta(j)-Sf_k))^-0.65*(abs(Beta(j)))^0.65*Rew^-0.2;
                        M_r_cone=cf_rotor*1/2*rhos1*(Beta(j)-Sf_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
                    else % 静锥面(Rew和cf同静径面）
                        Rew=rhos1*omega_ref*PosH^2/mu;
                        cf_stator=0.105*(abs(Sf_k))^-0.13*Rew^-0.2;
                        M_s_cone=cf_stator*1/2*rhos1*Sf_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
                    end
            end%若有螺栓，可在定义盘几何的函数里标记有螺栓的控制体flag=1，再加上螺栓的力矩
            M_rotor=M_rotor+M_r_disk+M_r_cylinder+M_r_cone;
            M_stator=M_stator+M_s_disk+M_s_cylinder+M_s_cone;
        end
    end
    eq1=M_rotor-M_stator;
    eq2=W*omega_ref*(R2^2*Sf_k-R1^2*Sf1);
    Sf_k=double(vpasolve(eq1-eq2));
    M_rotor=eval(M_rotor);
elseif omega_ref == 0
    Sf_k=0;
end
%% 能量方程：计算每个控制体的出口总温
% 总输入热：盘风阻和对流换热输入的热量
Q_windage=M_rotor*omega_ref; % 风阻输入热
A=abs(pi*R2^2-pi*R1^2); % 控制体圆环面积
% 计算换热温升
Q_ht = 0; % heat transfer
for j=1:l
    if ~isnan(data.boundary.htt(j))
        switch data.boundary.htt(j) % 计算换热温升
            case 0 % 给定热流
                Q_ht =  Q_ht + data.boundary.q(j)*A;
            case 1 % 给定壁温
                % Re=W*D/(mu*A);
                if omega(j) ~= 0 % 旋转壁面
                    Rew = rhos1*omega_ref*PosH^2/mu;% 旋转雷诺数
                    Nu=0.0545/3.14*(G/2)^0.1*Rew^0.8;
                    h = Nu*k/Rout;%对流换热系数h，控制体中心半径 Rm=(R1+R2)/2
                    Q_ht = Q_ht + h*A*(data.boundary.Tw(j)-Tt1);
                    % Nu可以替换不同的经验公式
                    h = Nu*k/Rout;%对流换热系数h，控制体中心半径 Rm=(R1+R2)/2
                    Q_ht = Q_ht + h*A*(data.boundary.Tw(j)-Tt1);
                elseif omega(j) == 0 % 静止壁面
                    Re=abs(rhos1*Vr1*2*G/mu); % Dh=4A/P=2G
                    if Re < 5e5 % 层流
                        Nu=0.664*Re^(1/2)*Pr^(1/3);
                    else % 湍流
                        Nu=0.037*Re^(4/5)*Pr^(1/3);
                    end
                    h = Nu*k/(abs(R2-R1)); % 特征长度为控制体高
                    Q_ht = Q_ht + h*A*(data.boundary.Tw(j)-Tt1);
                end
        end
    end
end
Tot_Qcell = Q_windage + Q_ht;
deltaT_windage=Q_windage/(W*cp);
deltaT_ht=Q_ht/(W*cp);
Tt2 = Tt1 + Tot_Qcell/(W*cp);% 出口总温
deltaT= Tt2 - Tt1;
%% 动量方程
%
Dh=2*G;
Rer=rhos1*Vr1*Dh/mu; % 径向雷诺数
Rew=rhos1*abs((1-Sf_k)*omega_ref)*Rm^2/mu;
roughness=1/2*(data.boundary.roughness(1)+data.boundary.roughness(3));
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
K=f_Darch*abs(R2-R1)/Dh;% Loss coefficient
%Pt2=Pt1-K*W^2/(2*rhos1*A1)+rhos1*(Sf_k*omega_ref)^2*abs(R2^2-R1^2)/2;

Pt2=Pt1+rhos1*(Sf_k*omega_ref)^2*abs(R2^2-R1^2)/2; % 涡旋压升造成总压变化
[state2]=WTcalcState(W,Pt2,Tt2,A2,data.Cons);%出口截面流动参数
rhos2=state2.rhos;
Ma2=state2.Ma;
Vr2=state2.V;
Ts2=state2.Ts;
V2=sqrt(Vr2^2+(Sf_k*omega_ref*Rout)^2);
Ps2=state2.Ps;


NErr=(Ps2-data.Ps2)/data.Ps2

ed.W=W;
ed.inlet=inlet;
ed.Ma2=Ma2;
ed.Pt2=Pt2;
ed.Ps2=Ps2;
ed.Tt2=Tt2;
ed.Ts2=Ts2;
ed.Sf2=Sf_k;%通过角动量守恒方程计算得
ed.rhos2=rhos2;
ed.Swirl2=Sf_k*omega_ref*Rout^2;
ed.V2=V2;
end