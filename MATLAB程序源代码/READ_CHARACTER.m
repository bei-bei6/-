%部件特性图读入程序，依次读入压气机，高压涡轮和低压涡轮的特性图。保存部件特性图数据为character
%%导入压气机特性
clc,clear,close All
addpath(genpath('.\整机性能模型'));
addpath(genpath('.\Solver'));
addpath(genpath('.\thermo'));
addpath(genpath('.\IFC67'));
addpath(genpath('.\Generator'));
addpath(genpath('.\parameter'));

loadCompressorCharacter;

scalar.HPC=[1 1 1 1];
figure
hold on
PlotCMap(MAP.HPC.Nc, MAP.HPC.Wc, MAP.HPC.PR, MAP.HPC.Eff,MAP.HPC.Rline,scalar.HPC)

%% 导入高压涡轮特性
loadTurbineChararcter;
HPTdate.X_Beta=linspace(0,1,num_bta);
HPTdate.X_Ncor_r=n;
HPTdate.Y_Eff=eta;
HPTdate.Y_Wcor=wa;
HPTdate.Y_PR=pr;
try
    save([pwd,'/parameter/character.mat'],'HPTdate','-append')
catch
    save([pwd,'/parameter/character.mat'],'HPTdate')
end
MAP.HPT.Nc=HPTdate.X_Ncor_r;
MAP.HPT.Wc=HPTdate.Y_Wcor;
MAP.HPT.Eff=HPTdate.Y_Eff;
MAP.HPT.PR=HPTdate.Y_PR;
MAP.HPT.Rline=HPTdate.X_Beta;      
scalar.HPT=[1 1 1 1];
figure
hold on
PlotTMap(MAP.HPT.Nc, MAP.HPT.Wc, MAP.HPT.PR, MAP.HPT.Eff,scalar.HPT) 

%% 导入动力涡轮特性
loadTurbineChararcter;
PTdate.X_Beta=linspace(0,1,num_bta);
PTdate.X_Ncor_r=n;
PTdate.Y_Eff=eta;
PTdate.Y_Wcor=wa;
PTdate.Y_PR=pr;
try
    save([pwd,'/parameter/character.mat'],'PTdate','-append')
catch
    save([pwd,'/parameter/character.mat'],'PTdate')
end
MAP.PT.Nc=PTdate.X_Ncor_r;
MAP.PT.Wc=PTdate.Y_Wcor;
MAP.PT.Eff=PTdate.Y_Eff;
MAP.PT.PR=PTdate.Y_PR;
MAP.PT.Rline=PTdate.X_Beta;

scalar.PT=[1 1 1 1];
figure
PlotTMap(MAP.PT.Nc, MAP.PT.Wc, MAP.PT.PR, MAP.PT.Eff,scalar.PT)

%% 补充一条动力涡轮转速线 ncor=2.5
clear
load([pwd,'/parameter/character.mat'])

Beta=PTdate.X_Beta;
n=PTdate.X_Ncor_r;
eta=PTdate.Y_Eff;
wa=PTdate.Y_Wcor;
pr=PTdate.Y_PR;
%

wa_add=interp2g(Beta,n,wa,0.5,n(end))-interp2g(Beta,n,wa,0.5,n(end-1));


wa=[wa;wa(end,:)+2.5*wa_add];
pr=[pr;pr(end,:)];
eta=[eta;eta(end,:)];
n=[n,2.5];


PTdate.X_Beta=Beta;
PTdate.X_Ncor_r=n;
PTdate.Y_Eff=eta;
PTdate.Y_Wcor=wa;
PTdate.Y_PR=pr;
try
    save([pwd,'/parameter/character.mat'],'PTdate','-append')
catch
    save([pwd,'/parameter/character.mat'],'PTdate')
end
