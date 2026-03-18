function [GasOut,ed]=SPSI(data)
Pt=data.Pt;
Tt=data.Tt;
Swirl=data.Swirl;
GasOut.Tt=Tt;
GasOut.Pt=Pt;
GasOut.Swirl=Swirl;
GasOut.Ptr=Pt;
ed=[];
end