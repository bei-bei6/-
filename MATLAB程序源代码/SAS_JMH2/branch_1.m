function [NErr,SAS_Data]=branch_1(x,data)
[SAS]=branch_Set_1(data.BC);
%% 支路1
SPSI1=SAS.SPSI1;% 引气

[Hole1O,Hole1D]=Hole(SPSI1,x(1),SAS.Hole1);
[Hole2O,Hole2D]=Hole(Hole1O,x(2),SAS.Hole2);
[Blade1O,Blade1D]=blade(Hole2O,data.BC.GasPrimary,x(3),SAS.HPT_Vane1);
[FH1O,FH1D]=HPTGuideVaneFilmHole(Blade1O,SAS.Pamb1,SAS.HPT_Vane.Trans1);

SAS_Data.Hole1O=Hole1O;
SAS_Data.Hole2O=Hole2O;
SAS_Data.Blade1O=Blade1O;
SAS_Data.FH1O=FH1O;

NErr=[Hole1O.W-Hole2O.W Hole2O.W-Blade1O.W Blade1O.W-FH1O.W];

NErr=NErr';
% fprintf('空气系统残差=%s\n',num2str(NErr','%f  '));
end