function randz=rrd(x,y,n)
randz=x+(y-x).*rand(length(x),n);
end