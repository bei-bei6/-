function PlotMap()
load('MAP.mat')
figure(1)
PlotCMap(MAP.HPC.Nc, MAP.HPC.Wc, MAP.HPC.PR, MAP.HPC.Eff,MAP.HPC.Rline)
figure(2)
PlotTMap(MAP.HPT.Nc, MAP.HPT.Wc,MAP.HPT.PR,  MAP.HPT.Eff)
figure(3)
PlotTMap(MAP.PT.Nc, MAP.PT.Wc,MAP.PT.PR,  MAP.PT.Eff)
end