function H=powT(A,N)
if(A < 10^-10 && A > -10^-10 && N < 0)
    H = 10^10;
else
    H = A^N;
end
end