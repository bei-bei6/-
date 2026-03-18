function lam=lamb(Q,A,R,y,P,T)
%仅适用于亚声速流动
%Q：流量
%A：面积
%R：气体常数
%y：热容比
%P：总压
%T：总温

%lam：气动常数
%气动函数q（lam）
K=sqrt((2/(y+1))^((y+1)/(y-1))*y/R);
q=Q*sqrt(T)/(K*A*P);

lam_left=0;
lam_right=1;
while 1
   lam=0.5*(lam_left+lam_right);
   f=((y+1)/2)^(1/(y-1))*lam*(1-(y-1)/(y+1)*lam*lam)^(1/(y-1))-q;
   if abs(f)<0.00001
       break;
   end
   if f<0
       lam_left=lam;
   else
       lam_right=lam;   
   end  
end