% 文件 1－Gllshort.m
% The function iprime = Gllshort(t, i) defines the differential
% equations of the synchronous machine during a
% phase-phase fault. The function returns the state derivatives
% of the current.
%current vector [-id,-iq,-i0,iF,iD,iQ]
% Copyright (c) 1998 H. Saadat, Modified by Jiang Qirong
function iprime =Gllshort_si(t,i,Generator)

VF=Generator.VF; %励磁电压

w=Generator.w;

Rs=Generator.Rs;%定子内阻
Rf=Generator.Rf;%励磁内阻
Rkd=Generator.Rkd;%阻尼D绕组内阻
Rkq=Generator.Rkq;%阻尼Q绕组内阻
r=Rs+Generator.R; %内阻+外阻

Lmd=Generator.Lmd;
Lmq=Generator.Lmq;
Lflou=Generator.Lloufd;
LDlou=Generator.Lloukd;
LQlou=Generator.Lloukq;
Llou=Generator.Llou;

Xad=Lmd;
Xaq=Lmq;
Xd=Lmd+Llou;
Xq=Lmq+Llou;
Xf=Lmd+Lflou;
XD=Lmd+LDlou;
XQ=Lmq+LQlou;

X0=1;
%
V = [0; 0; 0; VF; 0; 0]; % Voltage column vector负载电压
% K=3/2.; RT2=sqrt(2.0);
R=[r 0 0 0 0 0
0 r 0 0 0 0
0 0 r 0 0 0
0 0 0 Rf 0 0
0 0 0 0 Rkd 0
0 0 0 0 0 Rkq];

L=[Xd 0 0 Xad Xad 0
0 Xq 0 0 0 Xaq
0 0 X0 0 0 0
Xad 0 0 Xf Xad 0
Xad 0 0 Xad XD 0
0 Xaq 0 0 0 XQ];

WW=[0 -w 0 0 0 0
w 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0
0 0 0 0 0 0];
Li=inv(L);
iprime=Li*V-Li*(WW*L+R)*i;

end
