function x=X(Ma)
gamma=1.40;
x=(1-Ma.^2)./(gamma*Ma.^2)+(gamma+1)/(2*gamma)*log(((gamma+1)*Ma.^2)./(2*(1+(gamma-1)*Ma.^2/2)));
end