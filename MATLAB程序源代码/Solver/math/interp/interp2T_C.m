function zi= interp2T_C(X, Y, Z,xi,yi,A,B,error)
%涡轮的二阶插值程序，A是向量X的列数，B是向量Y的长度
i = A - 2;
j = B - 2;
errValue = 0;
err_Y=0;%特性线是否进行了延拓
%% 如果插值点在Y自变量范围外，那么将插值点调整到边界位置，并将errValue变为1

if (yi < Y(1))
    errValue = 1;
    yi = Y(1);
    
elseif (yi > Y(B))
    errValue = 1;
    yi = Y(B);
end

error = errValue;
%% 确定变量在Y方向的位置，yi位于Y(ii+1)和Y(ii+2)之间
 
while (j >= 0)
    if (yi >= Y(j+1))
        jj = j;
        break;
        
    else
        j = j - 1;
    end
end

%% 如果插值点在X自变量范围外，那么将插值点调整到边界位置，并将errValue变为1

%左边界位置：线性插值得到
slope_left=(X(jj+2,1)-X(jj+1,1))/(Y(jj+2) - Y(jj+1));
leftbound=X(jj+1,1)+slope_left*(yi-Y(jj+1));
%右边界位置
slope_right=(X(jj+2,A)-X(jj+1,A))/(Y(jj+2) - Y(jj+1));
rightbound=X(jj+1,A)+slope_right*(yi-Y(jj+1));

%延拓：仅进行左侧的延拓，如果压比在转速线范围外，将高转速的转速线进行延拓

if (xi < leftbound)
    err_Y=1;
%     errValue = 1;
%     xi = leftbound;
    k=(Z(jj+2,2)-Z(jj+2,1))/(X(jj+2,2)-X(jj+2,1));
    b=Z(jj+2,1)-k*X(jj+2,1);
    zi=k*xi+b;
    if zi<0
        zi=1;
    end
        
end  

if err_Y==0
    if (xi > rightbound)
        errValue = 1;
        xi = rightbound; 
    end
    %% 插值确定x上侧点所在位置，xi上侧投影点位于X（jj+1，ii+1）和X（jj+1，ii+2）之间
    while (i >= 0)
        if (xi >= X(jj+1,i+1))
            ii = i;
            break;    
        else
            i = i - 1;
        end
    end
    i = A - 2;
    slope1 = (Z(jj+B*(ii+1)+1) - Z(jj+B*ii+1))/(X(jj+B*(ii+1)+1) - X(jj+B*ii+1));
    z1 = Z(jj+B*ii+1) + (slope1 * (xi - X(jj+B*ii+1)));
    %% 插值确定x下侧点所在位置
    while (i >= 0)
        if (xi >= X(jj+2,i+1))
            ii = i;
            break;    
        else
            i = i - 1;
        end
    end
    slope2 = (Z(jj+1+B*(ii+1)+1) - Z(jj+1+B*ii+1))/(X(jj+1+B*(ii+1)+1) - X(jj+1+B*ii+1));
    z2 = Z(jj+1+B*ii+1) + (slope2 * (xi - X(jj+1+B*ii+1)));

    %% 基于z1和z2进行线性插值

    slope3 = (z2 - z1)/(Y(jj+1+1) - Y(jj+1));
    zi = z1 + (slope3 * (yi - Y(jj+1)));
end
end
