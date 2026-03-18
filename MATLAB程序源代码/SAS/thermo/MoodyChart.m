function f_Darch=MoodyChart(Re,k,dh)
f_Darch=0.25/(log10(k/(3.7*dh)+5.74/Re^0.9))^2;
end