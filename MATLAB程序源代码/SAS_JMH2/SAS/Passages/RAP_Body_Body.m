function [dydx,extra]=RAP_Body_Body(x,y,data)%旋转通道模型方程
R=data.Cons.R;
gamma=data.Cons.gamma;
g=data.Cons.g;
mu=data.Cons.mu;
k=data.Cons.k;%导热系数
cp=data.Cons.cp;

Ps=y(1);
V=y(2);
Ts=y(3);

Two=data.Two;
rho=Ps/(R*Ts);
%% 压力损失计算【计算摩擦因子f】
delta_x=(data.Node2.x-data.Node1.x)/(data.N+1);
i=round((x-data.Node1.x)/delta_x)+1;
L=sqrt((data.Node1.x-data.Node2.x)^2+(data.Node1.y-data.Node2.y)^2+(data.Node1.z-data.Node2.z)^2);
deltaL_i=L/(data.N+1);

r_ratio=data.d1/data.d2;
D=data.d2-data.d1;

w1=2*pi*(data.RESI/60);%内壁面转速rad/s
w2=2*pi*(data.RESO/60);%外壁面转速rad/s
Vg=sqrt(gamma*R*Ts);

if data.Node1.z~=0 || data.Node2.z~=0%if data.Node2.x-data.Node1.x~=L || data.Node1.z~=0 || data.Node2.z~=0
    fprintf('%s\n','环形旋转通道尺寸不连续, 要求z1=data.Node2.z=0')
    return
end

Re=rho*V*(data.d2-data.d1)/mu;
if data.RESI==0 && data.RESO==0% stationary passages 情况1：内外壁面均静止
    if Re<=2000 % 层流
        if (r_ratio<= 0)
            Cf=64; % Laminar flow coefficient
        elseif r_ratio >= 0.999
            Cf=96;
        else
            Cf=(64*(1-r_ratio)^2)/(1+ r_ratio^2+(1- r_ratio^2)/log(r_ratio));
        end
        f=Cf/Re;
    elseif Re>=4000 % 湍流
        f=0.25/(log10(data.roughness/(3.7*D)+5.74/Re^0.9))^2;
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
    end
else % 情况2：有且只有一个壁面旋转
    % f0=0.307*Re^-0.24;
    f0=0.25/(log10(data.roughness/(3.7*D)+5.74/Re^0.9))^2;%达西摩擦因子（3-14）
    if data.RESI~=0 && data.RESO==0% 内壁面旋转
        Rew=rho*abs(w1)*data.d1*(data.d1-data.d2)/(2*mu);
        f_f0=(1+(7/8)^2*(Rew/(2*Re))^2)^0.38;
        f=f_f0*f0;
    elseif data.RESI==0 && data.RESO~=0% 外壁面旋转
        Rew=rho*abs(w2*(data.d2^2-data.d1^2))/(4*mu);
        f_f0=RAP_f0Calc(Rew/Re,data.d1/data.d2);%外壁旋转摩擦修正系数【和论文对不上？】
        f=f_f0*f0;
    else %情况3：两壁面旋转
        Rew1=rho*abs(w1)*data.d1*(data.d1-data.d2)/(2*mu);
        f_f01=(1+(7/8)^2*(Rew1/(2*Re))^2)^0.38;
        f1=f_f01*f0;
        Rew2=rho*abs(w2*(data.d2^2-data.d1^2))/(4*mu);
        f_f02=RAP_f0Calc(Rew2/Re,data.d1/data.d2);
        f2=f_f02*f0;
        if data.RESI*data.RESO<0
            f=f1+f2;
            Rew=Rew1+Rew2;
        else
            f=abs(f1-f2);
            Rew=abs(Rew1-Rew2);
        end
    end
end
%% 传热计算【计算Q】
if data.type==0
    omega=0;
elseif data.type==1 %=1
    Text=293.15;%环境温度 待定
    if data.RESO==0 %情况1：外壁面静止
        alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;%alpha_v体积变化系数，对于理想气体即等于绝对温度的倒数
        Gr=abs(D^3*rho^2*alpha_v*(Ts-Text)/mu^2);
        Pr=cp*mu/k;
        if Gr*Pr>1e-5 && Gr*Pr<1e-3
            a=0.71;
            m=0.04;
        elseif Gr*Pr>1e-3 && Gr*Pr<1
            a=1.09;
            m=0.1;
        elseif Gr*Pr>1 && Gr*Pr<1e4
            a=1.09;
            m=0.2;
        elseif Gr*Pr>1e4 && Gr*Pr<1e9
            a=0.53;
            m=0.25;
        elseif Gr*Pr>1e9
            a=0.13;
            m=0.333;
        end
        Nu=a*(Gr*Pr)^m;
        h=Nu*k/D;
        q=h*(Two-Ts);
        P=pi*D;
        omega=q*P;
    else %情况2：外壁面旋转
        Re_ext=rho*pi*w2*data.d2^2/mu;
        Pr=cp*mu/k;
        alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
        Gr=abs(rho^2*alpha_v*g*(Two-Text)*D^3/mu^2);
        Nu=0.11*(0.5*Re_ext^2+Gr*Pr)^0.35;
        h=Nu*k/D;
        q=h*(Two-Ts);
        P=pi*D;
        omega=q*P;
    end
end

%% 控制方程
dydx=zeros(3,1);
Z=1;%CoolProp.PropsSI('Z','P',Ps,'T',Ts,'Air');
dZdT=0;%jacobianest(@(x) Z_T(x,Ps),Ts);
dZdP=0;%jacobianest(@(x) Z_P(x,Ts),Ps);

A=1/4*pi*(data.d2^2-data.d1^2);
if exist('f','var')==1 %exist检查变量的存在情况
    W=f*A/D*rho*V^2/2;
else
    fprintf('%s\n','f_Darch不存在')
end

dydx(1)=1/(V-Vg^2/V)*((Vg^2/(cp*Ts)*((omega+W*V)/A)*(1+dZdT*Ts/Z))+Vg^2*W/(V*A));%注意flowmaster给的是正号
dydx(2)=1/(Vg^2-V^2)*((Vg^2/(cp*Ts)*((omega+W*V)/(rho*A))*(1+dZdT*Ts/Z))+W*V/(rho*A));
dydx(3)=1/V*((Vg^2/(cp*Ps)*((omega+W*V)/A)*(1-dZdP*rho/Z))-(Vg^2/cp*dydx(2)*(1+dZdT*Ts/Z)));%【没看懂】

extra.f=f;
extra.deltaL_i=deltaL_i;
extra.Rew=Rew;%extra输出摩擦阻力系数，步长，旋转雷诺数
end