function [time,ieff]=CalcuRMS(t,ia,n) 
% n采样点数量，t时间序列，ia电流序列(交流电)
% time调整后时间序列，ieff电流有效值

    kk=length(t);
    tt=t(1:(kk-rem(kk,n)));
    iaa=ia(1:(kk-rem(kk,n)));
    lie=length(iaa)/n;

    tt=reshape(tt,[n,lie]);
    iaa=reshape(iaa,[n,lie]);
    time=tt(1,:);

    Max=max(iaa);
    Min=min(iaa);
    ieff=(0.5.*(Max-Min))./1.414213562373095;
    if rem(kk,n)
        Max=max(ia(end-n+1:end));
        Min=min(ia(end-n+1:end));
        ieff=[ieff,(0.5.*(Max-Min))./1.414213562373095];
        time=[time,t(end)];
    end
    
    
    
%     y=0; 
%     ga(1)=ia(1)^2; 
%     ga(2)=ia(2)^2; 
%     for i=3:n 
%         ga(i)=ia(i)^2; 
%         y=y+(ga(i-2)+4*ga(i-1)+ga(i))/6; 
%     end
%     ieff=sqrt(y/n);
%     time=t(1);
end








%计算有效值函数

%     y=0; 
%     ga(1)=data(1)^2; 
%     ga(2)=data(2)^2; 
%     for i=3:n 
%         ga(i)=data(i)^2; 
%         y=y+(ga(i-2)+4*ga(i-1)+ga(i))/6; 
%     end
%     y=sqrt(y/n);




