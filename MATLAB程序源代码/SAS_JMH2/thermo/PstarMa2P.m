function Ps=PstarMa2P(Pstar,Ma)%由总压转化为静压；Ps静压，Pstar总压；
gamma=1.40;%空气的比热容比
Ps=Pstar/(1+(gamma-1)/2*Ma^2)^(gamma/(gamma-1));%由总压计算静压：总压=静压*（1+((k-1)/2)*Ma^2)^(k/(k-1))
end