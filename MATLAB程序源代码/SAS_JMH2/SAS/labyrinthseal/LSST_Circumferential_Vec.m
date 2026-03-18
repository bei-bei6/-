function [V,taur,taus]=LSST_Circumferential_Vec(W,S,data)
%用周向动量方程计算齿腔内周向速度分布
R=data.Cons.R;
gamma=data.Cons.gamma;
mu=data.Cons.mu;

tol=1e-6;
% 计算周向速度
Dh=2*(data.Cri+data.Bi)*data.Li/(data.Cri+data.Bi+data.Li);%水力直径，式5.5
omega0=data.GasIn.Swirl/(data.Rsi+data.Bi+data.Cri/2)^2;
omega_Shaft=2*pi*data.RS/60; %rad/s
V0=omega0*(data.Rsi+data.Bi+data.Cri/2);
rhos0=data.GasIn.Pt/(R*data.GasIn.Tt);
for i=1:data.NT-1
    if i==1
        rho(i)=rhos0*(1+S(i))^(-gamma/(gamma-1));%由状态方程得密度之比等于压力之比
    else
        rho(i)=rho(i-1)*(1+S(i))^(-gamma/(gamma-1));
    end
    icount=1;imax=500;
    while 1
        if i==1 && icount==1
            V(i)=V0;
        elseif i~=1 && icount==1
            V(i)=V(i-1);
        end
        UGRW(i)=V(i)-(data.Rsi+data.Bi+data.Cri/2)*omega_Shaft;%相对转子速度
        UGSW(i)=V(i);
        Rerw(i)=abs(UGRW(i))*Dh*rho(i)/mu;
        Resw(i)=abs(UGSW(i))*Dh*rho(i)/mu;
        if Rerw(i)==0
            taur(i)=0;
        else
            taur(i)=-0.03955*rho(i)*(UGRW(i))^2*(Rerw(i))^-0.25*sign(UGRW(i));
        end
        if Resw(i)==0
            taus(i)=0;
        else
            taus(i)=0.03955*rho(i)*(UGSW(i))^2*(Resw(i))^-0.25*sign(UGSW(i));
        end
        if i==1
            Vn(i)=2*pi*data.Rsi*data.Li*(taur(i)*data.ari-taus(i)*data.asi)/W+V0;
        else
            Vn(i)=2*pi*data.Rsi*data.Li*(taur(i)*data.ari-taus(i)*data.asi)/W+V(i-1);
        end
        if abs(Vn(i)-V(i))<tol
            break
        else
            V(i)=Vn(i);
            icount=icount+1;
        end
        if icount>imax
            %fprintf('%s\n','LSST计算周向速度时无法收敛')
            return
        end
    end
end
end