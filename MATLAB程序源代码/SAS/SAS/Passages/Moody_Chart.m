function f=Moody_Chart(Re,k_Dh)
f=0.25/(log10(5.74/Re^0.9+k_Dh/3.7))^2;
end