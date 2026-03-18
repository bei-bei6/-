function yi=interp1Ac(X_A_FARVec,T_A_RtArray,FAR,A)
i=A-2;
if(FAR<X_A_FARVec(1))
    FAR=X_A_FARVec(1);
elseif(FAR>X_A_FARVec(A))
    FAR=X_A_FARVec(A);
elseif(FAR<X_A_FARVec(1))
    FAR=X_A_FARVec(1);
end
while(i>=0)
    if(FAR>=X_A_FARVec(i+1))
        ii=i;
        break
    else
        i=i-1;
    end
end
slope=(T_A_RtArray(ii+2)-T_A_RtArray(ii+1))/(X_A_FARVec(ii+2)-X_A_FARVec(ii+1));
yi=T_A_RtArray(ii+1)+(slope*(FAR-X_A_FARVec(ii+1)));

