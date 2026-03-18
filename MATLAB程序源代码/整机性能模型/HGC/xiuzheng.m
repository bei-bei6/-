function [delta_xiu, eta_xiu, MG_xiu, Mn_xiu] = xiuzheng(delta, eta, MN, MG, delta_min, delta_max, MG_min, MG_max, itd,otd, volute, L_itd, AR_itd, L_otd,AR_otd,L_diffuse, L_inner,theta_volute)

if (any(MN > 120))||any(MN < 50)||(otd ~= 0 && otd ~= 1)||(volute ~= 0 && volute ~= 1)
   error('wrong input')
end
if any(max(delta)>delta_max)||any(min(delta)<1.15)||any(min(MG)<MG_min)||any(max(MG)>MG_max)
     error('surpass the bound')
end


%归一化
Mn_xiu=MN;
A=MG;
B=MN;
C=delta;
range_A = [MG_min,MG_max];
range_C = [delta_min,delta_max];
new_range_A = [4.5 7.4];
new_range_C = [1.2,4];
A_normalized = normalize(A, 'range', range_A);
C_normalized = normalize(C, 'range', range_C);
A_normalized_mapped = new_range_A(1) + (A_normalized - min(A_normalized)) * (new_range_A(2) - new_range_A(1)) / (max(A_normalized) - min(A_normalized));
C_normalized_mapped = new_range_C(1) + (C_normalized - min(C_normalized)) * (new_range_C(2) - new_range_C(1)) / (max(C_normalized) - min(C_normalized));
x=MN;
y=A_normalized_mapped;
w=C_normalized_mapped;
%%
if itd==1%涡轮存在过渡段 
ans=L_itd;
bns=AR_itd;
p1=-6.04054715603342;p2=2.32224539678517;p3=2.81726140723273;p4=-0.317809684210242;p5=-0.604844128467152;p6=0.0111395039928426;p7=0.1124300186971;p8=-0.643108583000309;
p9=0.0693517957716437;p10=-0.0101545985766102;p11=-0.0018051212193693;p12=-0.0671325214838869;
z = (p1+p2.*log(x)+p3.*log(y)+p4.*log(x).^2+p5.*log(y).^2+p6.*log(x).^3+p7.*log(y).^3+p8.*log(x).*log(y)+p9.*log(x).^2.*log(y)+p10.*log(x).*log(y).^2).*(p11.*x.*y)+p12;
p1=-2459.73217805055;p2=604.023044414827;p3=241.456901906748;p4=460.087569689435;p5=34.8313602530166;p6=-34.126516189222;p7=2.55276479939082;p8=106.973731094972;
p9=-90.8283072112523;p10=-38.737027937209;
f=@(W,AR)(W.*AR./(p1+p2.*W+p3.*AR+p4.*W.^2+p5.*AR.^2+p6.*W.^3+p7.*AR.^3+p8.*W.*AR+p9.*W.^2.*AR+p10.*W.*AR.^2));
delta_xiu=delta;
eta_xiu = eta;  
MG_xiu = MG;
Mn_xiu = MN;
end
%% 
if otd==1%存在后扩压器
a1=8.0558294885046E-5  ;a2=-9.66156915615105E-5;a3=2.90062436253278E-5;b1=103171.549340874;b2=-135805.293406609;b3=45165.7164422157;d1=6.63617288420151;d2=-7.67979690023654;d3=2.54094687524961   ;
n1  =	4.96410425959445E-5 ;n2  =	-6.01572768578175E-5;n3  =	1.83101252000326E-5 ;m1  =	-10456.7256072805   ;m2  =	11797.4745786082    ;m3  =	-2745.0768118875    ;p1  =	-4.24725646063794 ;  
p2  =	6.31459689866406    ;p3  =	-1.96227434960764   ;
x=linspace(665,1600,60)' ;
y=linspace(1.5,1.66,60);
for i=1:length(y)
    z = d1+d2*y+d3*y.^2-(a1+a2*y+a3*y.^2).*(x-(b1+b2*y+b3*y.^2)).^2*0.9;
    o = p1+p2*y+p3*y.^2-(n1+n2*y+n3*y.^2).*(x-(m1+m2*y+m3*y.^2)).^2*0.9;
    xiuzhen=o./z;
end
xiuzhen=xiuzhen-0.017*ones(60,60);
p1=-2459.73217805055;p2=604.023044414827;p3=241.456901906748;p4=460.087569689435;p5=34.8313602530166;p6=-34.126516189222;p7=2.55276479939082;p8=106.973731094972;
p9=-90.8283072112523;p10=-38.737027937209;
f=@(W,AR)(W.*AR./(p1+p2.*W+p3.*AR+p4.*W.^2+p5.*AR.^2+p6.*W.^3+p7.*AR.^3+p8.*W.*AR+p9.*W.^2.*AR+p10.*W.*AR.^2));
f(L_otd,AR_otd);
 x=linspace(50,120,60)';
 y=linspace(4.5,7.4,60);
eta_xiu = eta.*griddata(x,y,xiuzhen,MN,A_normalized_mapped); 
delta_xiu=delta;
MG_xiu = MG*0.9907;
Mn_xiu = MN;
end
%%
if volute==1%涡轮存在蜗壳
% %流量修正
% syms x y
a1=58.75161571;a2 =-0.278996653;a3 =-13.89761876;b1 =-0.07870605;b2 =0.00053068;b3 =-2.05E-05;c1 =-5.225148942;c2 =0.06046796;c3 =-0.000154696;d1 =1.709357741;d2 =0.000410191;d3 =0.000802019;
n1=93.5416388998773;n2=-0.056633772395894;n3=-70.1030785520566;p1=-0.13511184070384;p2=0.00194575188874049;p3=-3.65325720566997E-5 ;q1=-4.24164355894148;q2=0.0542883460551611;q3=-0.000139999224925324;
t1=1.96394503124257;t2=0.0156011297227982;t3=0.000502627009403084 ; 
 v=linspace(50,120,60);
 u=linspace(1.2,4,60)';
 xiuzhen=zeros(60,60);
for i=1:length(u)
    z = ((a1.*v.^(a2)+a3).*(u-1).^(b1+b2.*v+b3.*v.^2)+c1+c2.*v+c3.*v.^2).*((u-1).*(2*d1+2*d2.*v+2*d3.*v.^2-u-1)).^0.5;
    o = ((n1.*v.^(n2)+n3).*(u-1).^(p1+p2.*v+p3.*v.^2)+q1+q2.*v+q3.*v.^2).*((u-1).*(2*t1+2*t2.*v+2*t3.*v.^2-u-1)).^0.5;
    xiuzhen=o./z;
end
xiuzhen(xiuzhen>0.971)=0.971;
xiuzhen=1-xiuzhen/500;
g=@(L1,L2, theta)L1/1000*(L1<1000)+L2/L1/100;
MG_xiu=MG.*griddata(u,v,xiuzhen,C_normalized_mapped,MN)*(1-g(L_diffuse,L_inner,theta_volute));

clear xiuzhen
% %效率修正
a1=0.00180651220585284;a2 =-0.000468878348707362;a3=3.10996934698331E-5;b1 =358.864117488561;b2 =-121.959742454915;b3=12.0713830997541;    
d1=0.957672311935491;d2=-0.0700813159716052;d3=0.00905836657521043 ;
n1=0.000303350212204548;n2=-3.39929071653808E-5;n3=1.15128661271385E-7 ;
p1=33.9476826801591    ;p2=-14.0497329794634   ;p3=3.28701998076592  ;  
q1=0.945243782665703   ;q2=-0.0585093576599245 ;q3=0.00755795731729544 ;
 x=linspace(50,120,60)';
 y=linspace(4.5,7.4,60);
 xiuzhen=zeros(60,60);
for i=1:length(x)
    z=d1+d2*y+d3*y.^2-(a1+a2*y+a3*y.^2).*(x-(b1+b2*y+b3*y.^2)).^2*0.9;
    o=q1+q2*y+q3*y.^2-(n1+n2*y+n3*y.^2).*(x-(p1+p2*y+p3*y.^2)).^2*0.9;
    xiuzhen=o./z;
end
xiuzhen(xiuzhen<1)=1.011326;
xiuzhen=1./xiuzhen;
k=@(L1,L2, theta)(L1<1000)*(L1^0.5+(L2/L1/100)^2*theta)/1000+(L1>=1000)*(L1-1000)/L1*sin(theta_volute)/100;
eta_xiu=eta.*(1-griddata(x,y,xiuzhen,MN,A_normalized_mapped)/10000)*(1-k(L_diffuse,L_inner,theta_volute));
delta_xiu=delta;
eta_xiu = eta_xiu; 
MG_xiu = MG_xiu;
Mn_xiu = MN;
end
