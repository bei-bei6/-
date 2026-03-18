function H=divby(X)
    if(X < 10^-10 && X > -10^-10)
        H = ((X >= 0) - (X < 0))*10^10;
    else
        H = 1/X;
    
    end
end