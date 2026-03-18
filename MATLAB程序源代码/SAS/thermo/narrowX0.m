function x0=narrowX0(P1,P2,n)
if abs(P1-P2)>1500
%     x0=[rand rand];
    x0=rrd(0,1,n);
elseif abs(P1-P2)>500
%     x0=[0.05*rand 0.05*rand];
    x0=rrd(0,0.05,n);
elseif abs(P1-P2)>200
%     x0=[0.005*rand 0.005*rand];
    x0=rrd(0,0.005,n);
else
%     x0=[0.003*rand 0.003*rand];
    x0=rrd(0,0.003,n);
end
end