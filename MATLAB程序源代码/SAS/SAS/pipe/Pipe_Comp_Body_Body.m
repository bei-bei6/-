function [dydx,extra]=Pipe_Comp_Body_Body(x,y,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
g=data.Cons.g;
cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;

Ps=y(1);
V=y(2);
Ts=y(3);

Tw=[data.Tw(1) data.Tw];
rho=Ps/(R*Ts);
%%
delta_x=(data.L-0)/data.N;
i=round((x-0)/delta_x)+1;
TAF=(Tw(i)+Ts)/2;
rhoA=Ps/(R*TAF);
%%
Vg=sqrt(gamma*R*Ts);
f_method=11;
Re=rhoA*V*data.d/mu;
if Re<=2000
    f=64/Re;
elseif Re>4000
    switch f_method
        case 1
            f=0.0055*(1+(2e4*data.roughness/data.d+10^6/Re)^(1/3));
        case 2
            a=0.53*(data.roughness/data.d)+0.094*(data.roughness/data.d)^0.225;
            b=88*(data.roughness/data.d)^0.44;
            c=1.62*(data.roughness/data.d)^0.134;
            f=a+b*Re^-c;
        case 3
            f=0.25/(log10(data.roughness/(3.7*data.d)+5.74/Re^0.9))^2;
        case 4%不行
            A=(-2*log10((data.roughness/data.d)/3.7+(7/Re)^0.9))^16;
            B=(37530/Re)^16;
            f=8*((8/Re)^12+(A+B)^(-3/2))^(1/12);
        case 5
            f=-2*log10(data.roughness/(3.7065*data.d)-5.0452/Re*log10(1/2.8257*(data.roughness/data.d)^1.1098)+5.8506/Re^0.8981);
            f=(1/f)^2;
        case 6
            f=-1.8*log10(0.27*data.roughness/data.d+6.5/Re);
            f=(1/f)^2;
        case 7
            f=-2*log10(data.roughness/(3.7*data.d)+4.5181*log10(1/7*Re)/(Re*(1+1/29*(data.d/2)^0.52*(data.roughness/data.d)^0.7)));
            f=(1/f)^2;
        case 8
            f=-2*log10(data.roughness/(3.7*data.d)-5.02/Re*log10(1/3.7*(data.roughness/data.d)-5.02/Re*log10(data.roughness/(3.7*data.d)+13/Re)));
            f=(1/f)^2;
        case 9
            f=-1.8*log10((data.roughness/(3.7*data.d))^1.11+6.9/Re);
            f=(1/f)^2;
        case 10
            f=-2*log10(data.roughness/(3.7*data.d)+95/Re^0.983-96.82/Re);
            f=(1/f)^2;
        case 11
            A=log10(data.roughness/data.d/3.827-4.567/Re*log10((data.roughness/data.d/7.7918)^0.9924+(5.3326/(208.815+Re))^0.9345));
            f=-2*log10(data.roughness/(3.7065*data.d)-5.0272/Re*A);
            f=(1/f)^2;
        case 12
            s=0.1240*(data.roughness/data.d)*Re+log(0.4587*Re);
            f=0.8686*log((0.4587*Re)/s^(s/(s+1)));
            f=(1/f)^2;
    end
else
    fl=64/2000;
    ft=0.25/(log10(data.roughness/(3.7*data.d)+5.74/4000^0.9))^2;
    x=(Re-2000)/2000;
    f=x*ft+(1-x)*fl;
end
f=f/1.2;
%%
if data.type==1
    % 外壁面换热，暂时忽略
    %{
    alpha_v=0.0036+10^-5*Ts+10^-8*Ts^2;
    Gr=abs(data.d^3*g*rhoA^2*alpha_v*(Ts-Tw(i))/mu^2);
    Pr=cpA*mu/kA;
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
    h=Nu*kA/data.d;
    q=h*(Tw(i)-Ts);
    P=pi*data.d;
    omega=q*P;
    %}
    Pr=cpA*mu/kA;
    Nu=0.023*Re^0.8*Pr^0.4;
    h=Nu*kA/data.d;
    q=h*(Tw(i)-Ts);
    P=pi*data.d;
    omega=q*P;
else
    omega=0;
end
%% 控制方程
dydx=zeros(3,1);

Z=1;
dZdT=0;%jacobianest(@(x) Z_T(x,Ps),Ts);
dZdP=0;%jacobianest(@(x) Z_P(x,Ts),Ps);
A=1/4*pi*data.d^2;
W=f*A/data.d*rho*V^2/2;
dydx(1)=1/(V-Vg^2/V)*((Vg^2/(cp*Ts)*((omega+W*V)/A)*(1+dZdT*Ts/Z))+Vg^2*W/(V*A)-rho*Vg^2*(g*sin(data.theta))/V);%注意flowmaster给的是正号
dydx(2)=1/(Vg^2-V^2)*((Vg^2/(cp*Ts)*((omega+W*V)/(rho*A))*(1+dZdT*Ts/Z))+W*V/(rho*A)-V*(g*sin(data.theta)));
dydx(3)=1/V*((Vg^2/(cp*Ps)*((omega+W*V)/A)*(1-dZdP*rho/Z))-(Vg^2/cp*dydx(2)*(1+dZdT*Ts/Z)));
extra.f=f;
end