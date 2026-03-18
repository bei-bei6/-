function yi= interp1g(X, Y,xi)
if isempty(Y)
    yi=0.0000000001;
else
    if xi>=X(end)
            k=(Y(end)-Y(end-1))/(X(end)-X(end-1));
            b=Y(end)-k*X(end);
            yi=k*xi+b;
    elseif xi<=X(1)
            k=(Y(2)-Y(1))/(X(2)-X(1));
            b=Y(1)-k*X(1);
            yi=k*xi+b;
    else 
        for i=1:length(X)
            if xi<=X(i+1)
                break;
            end
        end
        k=(Y(i+1)-Y(i))/(X(i+1)-X(i));
        b=Y(i)-k*X(i);
        yi=k*xi+b;
    end
end
end
