function Tq=Propeller(N)
% 船舶电力推进中燃气轮机发电机组建模与仿真, 计算机仿真》
Kpq=1;%转矩系数
rho=1000;%静水的密度
D=1;%螺旋桨直径
np=N;%转速

Tq=Kpq*rho*D^5*np^2;%扭矩

end