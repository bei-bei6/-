function zi=interp2K(DATA,xi,yi)
X=DATA(:,1);
Y=DATA(:,2);
Z=DATA(:,3);
uy=unique(Y);
X=X';
Z=Z';
%
if (yi < uy(1))
    yi = Y(1);
elseif (yi > uy(end))
    yi = uy(end);
end
%


for i=1:length(uy)
    p(i)=length(find(Y==uy(i)));
    pp=Y==uy(i);
    x{i,1}=X(pp);
    z{i,1}=Z(pp);
end

j=length(x)-1;
while (j >= 0)
    if (yi >= uy(j+1))
        jj = j;
        jj=jj+1;
        break;
    else
        j = j - 1;
    end
end
%
for m=1:length(x)
    [x{m},x_m]=sort(x{m});
    z{m}=z{m}(x_m);
end
%
if jj==length(x)
    x_n=x{jj};
    z_n=z{jj};

else
    x_l=x{jj};
    x_r=x{jj+1};
    z_l=z{jj};
    z_r=z{jj+1};
    if length(x_l)==length(x_r)
        x_n=(x_r-x_l)*(yi-uy(jj))/(uy(jj+1)-uy(jj))+x_l;
        z_n=(z_r-z_l)*(yi-uy(jj))/(uy(jj+1)-uy(jj))+z_l;
    else
        %%
        if length(x_l)>length(x_r)
            len1=length(x_r);%最短
            len2=length(x_l);%最长
            x1=x_r;%最短
            x2=x_l;
            z1=z_r;%最短
            z2=z_l;
        else
            len1=length(x_l);%最短
            len2=length(x_r);%最长
            x1=x_l;
            x2=x_r;
            z1=z_l;
            z2=z_r;
        end
        for i=1:len1
            p=find(abs(x2-x1(i))==min(abs(x2-x1(i))));
            x_n(i)=(x2(p)-x1(i))*(yi-uy(jj))/(uy(jj+1)-uy(jj))+x1(i);
            z_n(i)=(z2(p)-z1(i))*(yi-uy(jj))/(uy(jj+1)-uy(jj))+z1(i);
        end
    end
end
%
% [x_n,x_n_p]=sort(x_n);
% z_n=z_n(x_n_p);
%
if (xi < x_n(1))
    xi = x_n(1);
elseif (xi > x_n(end))
    xi = x_n(end);
end



i=length(x_n)-1;
while (i >= 0)
    if (xi >= x_n(i+1))
        ii = i;
        ii=ii+1;
        break;
    else
        i = i - 1;
    end
end
if ii==length(x_n)
    zi=z_n(ii);
else
    zi=(z_n(ii+1)-z_n(ii))*(xi-x_n(ii))/(x_n(ii+1)-x_n(ii))+z_n(ii);
end