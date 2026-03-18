function [GasOut,ed]=HPTGuideVaneFilmHole(GasIn,Ptb,data)
[GasOut,ed]=ATran(GasIn,Ptb,data);
GasOut.W=GasOut.W*data.Num;
end