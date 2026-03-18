function [NErr,SAS_Data]=branch_3(x3,data)
[SAS]=branch_Set_3(data.BC);
%% 支路3
SPSI3_1=SAS.SPSI1;
SAS.Pamb3_1=SAS.Pamb1;
SAS.Pamb3_2=SAS.Pamb2;

[Pipe3_1O,Pipe3_1D]=Pipe(SPSI3_1,x3(1),SAS.Pipe3_1);
[Blade3_1O,Blade3_1D]=blade(Pipe3_1O,data.BC.GasPrimary,x3(2),SAS.LPT_Vane3_1);
% branch 3
[FH3_1O,FH3_1D]=LPTGuideVaneFilmHole(Blade3_1O,SAS.Pamb3_1,SAS.LPT_Vane.Trans1);
% branch 4
[Hole3_1O,Hole3_1D]=Hole(Blade3_1O,x3(3),SAS.Hole3_1);
[Hole3_2O,Hole3_2D]=Hole(Blade3_1O,x3(3),SAS.Hole3_2);
MixGas=Mix(Hole3_1O,Hole3_2O);
[rimseal3_1O,rimseal3_1D]=LSST(MixGas,SAS.Pamb3_2,SAS.rimseal3_1);
 
SAS_Data.Pipe3_1O=Pipe3_1O;SAS_Data.Pipe3_1D=Pipe3_1D;
SAS_Data.Blade3_1O=Blade3_1O;SAS_Data.Blade3_1D=Blade3_1D;
SAS_Data.FH3_1O=FH3_1O;SAS_Data.FH3_1D=FH3_1D;
SAS_Data.Hole3_1O=Hole3_1O;SAS_Data.Hole3_1D=Hole3_1D;
SAS_Data.Hole3_2O=Hole3_2O;SAS_Data.Hole3_2D=Hole3_2D;
SAS_Data.MixGas=MixGas;
SAS_Data.rimseal3_1O=rimseal3_1O;SAS_Data.rimseal3_1D=rimseal3_1D;

NErr=[Pipe3_1O.W-Blade3_1O.W Blade3_1O.W-(Hole3_1O.W+Hole3_2O.W+FH3_1O.W) MixGas.W-rimseal3_1O.W];

NErr=NErr';
fprintf('空气系统残差=%s\n',num2str(NErr','%f  '));
end