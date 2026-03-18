function Ps=PstarMa2P(Pstar,Ma)
gamma=1.40;
Ps=Pstar/(1+(gamma-1)/2*Ma^2)^(gamma/(gamma-1));
end