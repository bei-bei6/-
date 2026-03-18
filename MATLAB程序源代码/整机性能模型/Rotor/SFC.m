function [SFC,Fnet]=SFC(Wf,Fg,Fram)
SFC=Wf*3600/(Fg-Fram);
Fnet=Fg-Fram;
end