function T=TstarMa2T(Tstar,Ma)
gamma=1.40;
T=Tstar/(1+(gamma-1)/2*Ma^2);
end