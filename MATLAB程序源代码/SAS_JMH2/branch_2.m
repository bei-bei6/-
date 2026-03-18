function [NErr,SAS_Data]=branch_2(x,data)
[SAS]=branch_Set_2(data.BC);
%% 支路2
SPSI1=SAS.SPSI1;

[Hole1O,Hole1D]=Hole(SPSI1,x(1),SAS.Hole1);
[Hole2O,Hole2D]=Hole(Hole1O,x(2),SAS.rechol);
[BladeO,BladeD]=blade(Hole2O,data.BC.GasPrimary,SAS.Pamb1,SAS.Blade);

SAS_Data.Hole1O=Hole1O;
SAS_Data.Hole1D=Hole1D;
SAS_Data.Hole2O=Hole2O;
SAS_Data.Hole2D=Hole2D;
SAS_Data.BladeO=BladeO;
SAS_Data.BladeD=BladeD;

NErr=[Hole1O.W-Hole2O.W Hole2O.W-BladeO.W];

NErr=NErr';
% fprintf('空气系统残差=%s\n',num2str(NErr','%f  '));
end