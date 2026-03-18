function zi= interp2Ac(X, Y, Z,xi,yi)
% i = A - 2;
% j = B - 2;

A=length(X);
B=length(Y);
i = A - 2;
j = B - 2;
errValue = 0;
if (xi < X(1))
    errValue = 1;
    xi = X(1);
    
elseif (xi > X(A))
    errValue = 1;
    xi = X(A); 
end

if (yi < Y(1))
    errValue = 1;
    yi = Y(1);
    
elseif (yi > Y(B))
    errValue = 1;
    yi = Y(B);
end

error = errValue;
while (i >= 0)
    if (xi >= X(i+1))
        ii = i;
        break;
        
    else
        i = i - 1;
    end
end

while (j >= 0)
    if (yi >= Y(j+1))
        jj = j;
        break;
        
    else
        j = j - 1;
    end
end


slope1 = (Z(jj+B*(ii+1)+1) - Z(jj+B*ii+1))/(X(ii+1+1) - X(ii+1));
z1 = Z(jj+B*ii+1) + (slope1 * (xi - X(ii+1)));


slope2 = (Z(jj+1+B*(ii+1)+1) - Z(jj+1+B*ii+1))/(X(ii+1+1) - X(ii+1));
z2 = Z(jj+1+B*ii+1) + (slope2 * (xi - X(ii+1)));

slope3 = (z2 - z1)/(Y(jj+1+1) - Y(jj+1));
zi = z1 + (slope3 * (yi - Y(jj+1)));
end
