function [dydx,extra]=RP_Body_Body(x,y,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
g=data.Cons.g;
mu=data.Cons.mu;
k=data.Cons.k;
cp=data.Cons.cp;

Ps=y(1);
V=y(2);
Ts=y(3);

Tw=data.Tw;
rho=Ps/(R*Ts);
%%
L=sqrt((data.Node1.x-data.Node2.x)^2+(data.Node1.y-data.Node2.y)^2+(data.Node1.z-data.Node2.z)^2);
delta_L=L/data.N;
delta_x=(data.Node2.x-data.Node1.x)/data.N;
delta_y=(data.Node2.y-data.Node1.y)/data.N;
delta_z=(data.Node2.z-data.Node1.z)/data.N;
if data.Node1.x~=data.Node2.x
    i=round((x-data.Node1.x)/delta_L)+1;
else
    i=round((x-data.Node1.y)/delta_y)+1;
end
L=sqrt((data.Node1.x-data.Node2.x)^2+(data.Node1.y-data.Node2.y)^2+(data.Node1.z-data.Node2.z)^2);

w=2*pi*(data.RES/60);
TAF=(Tw+Ts)/2;
rhoA=Ps/(R*TAF);
Vg=sqrt(gamma*R*Ts);

rl=sqrt((data.Node1.y+(i-1)*delta_y)^2+(data.Node1.z+(i-1)*delta_z)^2);
rr=sqrt((data.Node1.y+i*delta_y)^2+(data.Node1.z+i*delta_z)^2);
deltaL_i=L/(data.N);
xr=data.Node1.x+i*delta_x;
xl=data.Node1.x+(i-1)*delta_x;
yr=data.Node1.y+i*delta_y;
yl=data.Node1.y+(i-1)*delta_y;
zr=data.Node1.z+i*delta_z;
zl=data.Node1.z+(i-1)*delta_z;
x_mid=(xl+xr)/2;
y_mid=(yl+yr)/2;
z_mid=(zl+zr)/2;
%% 摩擦损失
r1=sqrt(data.Node1.y^2+data.Node1.z^2);
r2=sqrt(data.Node2.y^2+data.Node2.z^2);
Re=rho*V*data.d/mu;
Rew=rho*w*data.d^2/mu;
N_Rotation=Rew/Re;
k_Dh=data.roughness/data.d;
if r1==0 && r2==0 % Axially-symmetric
    ae=0;
    if Re>82.9 && Re<2000 % 层流
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(Re,Rew);
        f=f_f0*64/Re;
    elseif Re>=2000 && Re<=4000% 过渡流
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(2000,Rew);
        f1=0.032*f_f0;
        f2=Moody_Chart(4000,k_Dh);
        f=(f1+f2)/2;
    elseif Re>4000% 湍流
        f=Moody_Chart(Re,k_Dh);
    end
elseif r1==r2 % Parallel-Axis Rotating Passages
    cos_beta=(y_mid*(yr-yl)+z_mid*(zr-zl))/(deltaL_i*sqrt(y_mid^2+z_mid^2));
    ae=w^2*(rl+rr)/2*cos_beta;% Effective Acceleration
    if Re>82.9 && Re<2000 % 层流
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(Re,Rew);
        f=f_f0*64/Re;
    elseif Re>=2000 && Re<=4000% 过渡流
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(2000,Rew);
        f1=0.032*f_f0;
        f2=Moody_Chart(4000,k_Dh);
        f=(f1+f2)/2;
    elseif Re>4000% 湍流
        f=Moody_Chart(Re,k_Dh);
    end
elseif  abs((y_mid*(yr-yl)+z_mid*(zr-zl))/(deltaL_i*sqrt(y_mid^2+z_mid^2))-1)>1e-6% cos_beta~=1% Non-parallel Axis Rotating Passages
    cos_beta=(y_mid*(yr-yl)+z_mid*(zr-zl))/(deltaL_i*sqrt(y_mid^2+z_mid^2));
    ae=w^2*(rl+rr)/2*cos_beta;
    if Re<2000 % 层流Re>82.9 &&
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(Re,Rew);
        f_f0_non=1+(f_f0-1)*cos_beta;
        f=f_f0_non*64/Re;
    elseif Re>=2000 && Re<=4000% 过渡流(未查找到计算方法)
        f_f0=Friction_Correction_Factor_for_Rotation_in_Parallel_Ducts(2000,Rew);
        f1=0.032*f_f0;
        f2=Moody_Chart(4000,k_Dh);
        f=(f1+f2)/2;
    elseif Re>4000% 湍流(未查找到计算方法)
        f=Moody_Chart(Re,k_Dh);
    else
        disp(22)
    end
else % Radial-Axis Rotating Passages
    cos_beta=(y_mid*(yr-yl)+z_mid*(zr-zl))/(deltaL_i*sqrt(y_mid^2+z_mid^2));
    ae=w^2*(rl+rr)/2*cos_beta;
    if Rew>28 && Rew<2000
        Re_Transition=1070*Rew^0.23;
    else
        Re_Transition=2300;
    end
    if Re<Re_Transition % 层流
        if Re*Rew>220 && Re*Rew<10^7
            f_f0=0.0883*(Re*Rew)^0.25*(1+11.2/(Re*Rew)^0.325);
        elseif Re*Rew<220
            f_f0=1;
        end
        f=f_f0*64/Re;
    else %湍流
        if N_Rotation*Rew>1% && N_Rotation*Rew<500,bug不需要乘以Rew？
            f_f0=0.942+0.058*(N_Rotation*Rew)^0.282;
        elseif N_Rotation*Rew<=1
            f_f0=1;
        end
        f=f_f0*0.3164*Re^-0.25;
    end
end
%% 传热计算
if data.type==0
    omega=0;
elseif data.type==1
    if data.RES>=0 % 通道静止，采用Dittus-Boelter equation
        a=0.023;b=0.8;c=0.4;
        Pr=cp*mu/k;
        Nu=a*Re^b*Pr^c;
        h=Nu*k/data.d;
        q=h*(Tw-Ts);
        P=pi*data.d;
        omega=q*P;
    else
        if r1==0 && r2==0 % Axially-symmetric
            Re_wc=rho*w*d^2/mu;
            Pr=cp*mu/k;
            alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
            dTdx=abs(Tw-Ts);
            Gr=(rl+rr)/2*w^2*rho*alpha_v*dTdx*d^4/(16*mu^2);
            Nu=0.11*(0.5*Re_wc^2+Gr*Pr)^0.35;
        elseif abs(cos_beta-1)>1e-6
            if Re>82.9 && Re<2000 % 层流
                Pr=cp*mu/k;
                alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
                dTdx=abs(Tw-Ts);
                Gr=(rl+rr)/2*w^2*rho*alpha_v*dTdx*d^4/(16*mu^2);
                Rar = Gr*Pr;
                if Pr<10
                    zeta=1/5*(2+sqrt(10/Pr^2-1));
                    Nu=1.19/zeta*(zeta-1+1/(3*zeta))^0.2*(Rar*Re)^0.2/(1+1/(10*zeta*Pr));
                else
                    zeta=2/11*(1+sqrt(1+77/(4*Pr^2)));
                    Nu=0.883/zeta*(3*zeta-1)^0.2*(Rar*Re)^0.2/(1+1/(10*zeta*Pr));
                end
            elseif Re>=2000 && Re<=4000% 过渡流（未找到，暂时采用湍流计算方法）
                Pr=cp*mu/k;
                alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
                dTdx=abs(Tw-Ts);
                Gr=(rl+rr)/2*w^2*rho*alpha_v*dTdx*data.d^4/(2*mu^2);
                omicron=(Re^9/(Gr*Pr^(3/2))^5)^(2/11);
                Nu=0.043*Pr/(Pr^(2/3)-0.55)*Re^0.8/omicron^0.1*(1+0.061/(Re/omicron^2)^0.2);
            elseif Re>4000% 湍流
                Pr=cp*mu/k;
                alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
                dTdx=abs(Tw-Ts);
                Gr=(rl+rr)/2*w^2*rho^2*alpha_v*dTdx*data.d^4/(2*mu^2);
                omicron=(Re^9/(Gr*Pr^(2/3))^5)^(2/11);
                Nu=0.043*Pr/(Pr^(2/3)-0.55)*Re^0.8/omicron^0.1*(1+0.061/(Re/omicron^2)^0.2);
            end
        else % Radial-Axis Rotating Passages
            if Rew>28 && Rew<2000
                Re_Transition=1070*Rew^0.23;
            else
                Re_Transition=2300;
            end
            Pr=cp*mu/k;
            if Re<Re_Transition % 层流
                w_c=1/2*Rew;
                chi=sqrt(1+1.25*(w_c/Re)^2)-1.118*w_c/Re;
                if w_c/Re<Pr/2.236*(1-1/Pr^2)
                    xi=2/11*(1+sqrt(1+77/(4*chi*Pr^2)));
                else
                    xi=1/5*(2+sqrt(10/(chi*Pr^2)-1));
                end
                N=w_c*Re;
                if w_c/Re<Pr/2.236*(1-1/Pr^2)
                    Nu_Nu0=0.943/xi*(N/chi)^0.25/(1-4.8*(1-0.176/xi-0.07/(xi*Pr)*(1/xi+4.333))*(N/chi)^-0.25);
                else
                    Nu_Nu0=0.943/xi*(N/chi)^0.25/(1-2.82*(xi+0.5/xi-0.1/xi^2-0.8/(xi*Pr)*(xi-0.25/xi+0.05/xi^2))*(N/chi)^-0.25);
                end
                Nu=Nu_Nu0*4.364;
            else % 湍流
                w_c=1/2*Rew;
                capital_gamma=Re/w_c;
                chi=(1+5.14/capital_gamma^2)^0.5*2.27/capital_gamma;
                Nu=0.039*Pr/(Pr^(2/3)-0.074)*Re^0.8/(capital_gamma*chi)^0.1*(1+0.093/(Re/(capital_gamma*chi)^2));
            end
        end
        h=Nu*k/data.d;
        q=h*(Tw-Ts);
        P=pi*data.d;
        omega=q*P;
    end
elseif data.type==2
    P=pi*data.d;
    omega=data.q*1000*P;
end
%% 控制方程
dydx=zeros(3,1);
Z=1;%CoolProp.PropsSI('Z','P',Ps,'T',Ts,'Air');
dZdT=0;%jacobianest(@(x) Z_T(x,Ps),Ts);
dZdP=0;%jacobianest(@(x) Z_P(x,Ts),Ps);
A=1/4*pi*data.d^2;
if exist('f','var')==1
    W=f*A/data.d*rho*V^2/2;
else
    fprintf('%s\n','f_Darch不存在')
end
if r1==0 && r2==0 % Axially-symmetric
    dydx(1)=1/(V-Vg^2/V)*((Vg^2/(cp*Ts)*((omega+W*V)/A)*(1+dZdT*Ts/Z))+Vg^2*W/(V*A));
    dydx(2)=1/(Vg^2-V^2)*((Vg^2/(cp*Ts)*((omega+W*V)/(rho*A))*(1+dZdT*Ts/Z))+W*V/(rho*A));
    dydx(3)=1/V*((Vg^2/(cp*Ps)*((omega+W*V)/A)*(1-dZdP*rho/Z))-(Vg^2/cp*dydx(2)*(1+dZdT*Ts/Z)));
else
    theta=asin(zl/rl);
    dydx(1)=1/(V-Vg^2/V)*((Vg^2/(cp*Ts)*((omega+W*V)/A)*(1+dZdT*Ts/Z))+Vg^2*W/(V*A)-rho*Vg^2*(ae+g*sin(theta))/V);
    dydx(2)=1/(Vg^2-V^2)*((Vg^2/(cp*Ts)*((omega+W*V)/(rho*A))*(1+dZdT*Ts/Z))+W*V/(rho*A)-V*(ae+g*sin(theta)));
    dydx(3)=1/V*((Vg^2/(cp*Ps)*((omega+W*V)/A)*(1-dZdP*rho/Z))-(Vg^2/cp*dydx(2)*(1+dZdT*Ts/Z)));
end
extra.f=f;
extra.deltaL_i=deltaL_i;
end