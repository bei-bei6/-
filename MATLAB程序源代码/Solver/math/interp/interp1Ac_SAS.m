function yi=interp1Ac_SAS(X,Y,xi,A)
i=A-2;
[X,id]=sort(X);
Y=Y(id);

if(xi<min(X))
    xi=X(1);
elseif(xi>max(X))
    xi=X(A);
end
while(i>=0)
    if(xi>=X(i+1))
        ii=i;
        break
    else
        i=i-1;
    end
end
slope=(Y(ii+2)-Y(ii+1))/(X(ii+2)-X(ii+1));
yi=Y(ii+1)+(slope*(xi-X(ii+1)));

