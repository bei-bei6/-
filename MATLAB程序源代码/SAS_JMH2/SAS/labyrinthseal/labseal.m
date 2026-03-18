function [GasOut,ed]=labseal(GasIn,data)
gamma=data.Cons.gamma;
R=data.Cons.R;
%
Psout=data.Psout;
Cr=data.Cr;
t=data.t;
L=data.L;
Rs=data.Rs;
N=data.N;
A=pi*(2*(Rs)+Cr)*Cr;
% 检查是否存在逆流
if Psout>GasIn.Pt
    fprintf('%s\n','孔口存在逆流')
    [GasIn,Psout]=swap(GasIn,Psout);
    adverse=-1;
else
    adverse=1;
end
% 检查是否达到临界状态
if GasIn.Pt/Psout>=((gamma+1)/2)^(gamma/(gamma-1))
    fprintf('%s\n','孔口达到临界状态')
    choke=1;
    Psout=GasIn.Pt/(((gamma+1)/2)^(gamma/(gamma-1)));
else
    choke=0;
end

Pt1=GasIn.Pt;
Tt1=GasIn.Tt;

if Cr/t>1.3 && Cr/t<2.4
    Cd=0.748;
else
    fprintf('%s\n','封严篦齿缺少Cd')
    return
end

Kco=sqrt(1/(1-(N-1)/N*Cr/L/(Cr/L+0.02))*N/(N-1));
W=Cd*Kco*A*Pt1/sqrt(R*Tt1)*sqrt((1-(Psout/Pt1)^2)/(N+log(Pt1/Psout)));
GasOut.W=adverse*W;
GasOut.Pt=GasIn.Pt;
GasOut.Tt=GasIn.Tt;
GasOut.Swirl=GasIn.Swirl;
ed=[];
end