function PPDP
figure(1)
load Friction_Factor_For_Axially_Symmetric_Passage.mat Friction_Factor_For_Axially_Symmetric_Passage
X=Friction_Factor_For_Axially_Symmetric_Passage(:,1);
Y=Friction_Factor_For_Axially_Symmetric_Passage(:,2);
Z=Friction_Factor_For_Axially_Symmetric_Passage(:,3);
uy=unique(Y);
for i=1:length(uy)
    p=find(Y==uy(i));
    plot3(X(p),Y(p),Z(p),'LineWidth',1.5,'Color','b')
    hold on
end
grid on
title('Friction Factor - Axially Symmetric Rotating Passage')
xlabel('Reynolds Number Re');
ylabel('Rotation Number');
zlabel('Friction Factor');
clear
figure(2)
xx=linspace(log(4000),log(1e10),50);
y=linspace(0,0.1,50);
[X,Y]=meshgrid(exp(xx),y);
f=0.25./(log10(5.74./X.^0.9+Y./3.7)).^2;
ff=log(f);
surf(xx,Y,ff)
title('Moody Chart, f v Re & k/Dh')
xlabel('ln(Reynolds Number, Re)');
ylabel('Relative Roughness, k/Dh (Aspect Ratio)');
zlabel('ln(Loss Coefficient)');
clear
figure(3)
x=linspace(82.9,2300,50);
y=linspace(0,1000,50);
[X,Y]=meshgrid(x,y);
f=(X./82.9).^(0.7233.*log10(1.0+0.664.*(1.0-exp(-0.003746.*Y))));
surf(X,Y,f)
title('Friction Correction Factor for Rotation in Parallel Ducts (Fritzsche)')
xlabel('Axial Reynolds Number');
ylabel('Tangential Reynolds Number');
zlabel('Friction Correction Factor');
clear
figure(4)
x=0:2000;
f=2300*(x<28)+(1070*x.^0.23).*(x>=28);
plot(x,f,'LineWidth',1.5,'Color','b')
title('Transition Re v Rotational Re for Radial Ducts')
xlabel('Rotational Re');
ylabel('Transition Re');
clear
figure(5)
x=0:10:2000;
y=0:10:2000;
[X,Y]=meshgrid(x,y);
for i=1:length(X)
    for j=1:length(Y)
        if Y(i,j)<0.1*X(i,j) || X(i,j)*Y(i,j)<220
            Z(i,j)=1;
        elseif Y(i,j)>4*X(i,j)
            Z(i,j)=0.0672*Y(i,j)^0.5/(1-2.11*Y(i,j)^-0.5);
        else
            Z(i,j)=0.0883*(X(i,j)*Y(i,j))^0.25*(1+11.2/(X(i,j)*Y(i,j))^0.325);
        end
    end
end
surf(X,Y,Z)
title('Laminar Friction Correction Factor for Rotation in Radial Ducts')
xlabel('Axial Reynolds Number');
ylabel('Rotational Reynolds Number');
zlabel('Correction Factor, f/f0');
clear
figure(6)
x=0:5:1000;
y=0:10:2000;
[X,Y]=meshgrid(x,y);
for i=1:length(X)
    for j=1:length(Y)
        if X(i,j)*Y(i,j)<1
            Z(i,j)=1;
        else
            Z(i,j)=0.942+0.058*(X(i,j)*Y(i,j))^0.282;
        end
    end
end
surf(X,Y,Z)
title('Turbulent Friction Correction Factor for Rotation in Radial Ducts')
xlabel('Rotation Number, N');
ylabel('Rotational Reynolds Number');
zlabel('Correction Factor, f/f0');
end