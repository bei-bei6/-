
function F= funwrapper1(a11,x,Power_HPC,P4,T4,FAR,htOut,WOut)
F = a11(x,Power_HPC,P4,T4,FAR,htOut,WOut);
F = F(:);
end