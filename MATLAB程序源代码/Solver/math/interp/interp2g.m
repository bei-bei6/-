function zi= interp2g(X, Y, Z,xi,yi)
% i = A - 2;
% j = B - 2;
% A=length(X);
B=length(Y);
z=zeros(1,B);
for i=1:B
    u=Z(i,:);
    z(i)=interp1g(X,u,xi);
end
zi=interp1g(Y,z,yi);
% zi=interp2(X, Y, Z,xi,yi,'linear','extrap');
end
