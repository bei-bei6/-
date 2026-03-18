function TT=inertia(t,T,c,W,P,FAR,Area)
switch nargin
    case 3
        TT(1)=T(1);
        for i=2:length(t)
            TT(i)=T(i)+(TT(i-1)-T(i))*exp(-(t(2)-t(1))*divby(c));
        end
    case 7
        TT(1)=T(1);
        for i=2:length(t)
            [u,Pr]=t2uPr(T(i));%动力粘度与普朗克数
            [~,vis,density]=TWPAFAR2Pb(T(i),W(i),P(i),Area,FAR(i),0);
            b=c*(density*vis/u)^0.8*Pr^0.33333;
            TT(i)=T(i)+(TT(i-1)-T(i))*exp(-(t(2)-t(1))*divby(b));
        end  
    otherwise
        printf('传感器温度延迟环节参数输入有误')
end

end

function [Pb,V,rhos]=TWPAFAR2Pb(TtIn,W,P,Area,FARIn,d)
%根据总温总压流量和截面积求解出口背压和气流速度
%TtIn总温,W流量,P总压,Area面积,FARIn油气比,d湿度
%Pb背压,V速度,rhos密度
    d=0;
    Pb=0.999*P;
    left=0.2*P;
    right=P;
    i=0;
    while 1
        Pb=0.5*(left+right);
        htin=tf_dp2h(TtIn,FARIn);
        S = ptf_d2s(P,TtIn,FARIn)+log(abs(Pb/P));%入口熵=出口熵
        Ts = spf_d2t(S,Pb,FARIn,d);%出口静温
        if (Ts > TtIn)
            Ts = TtIn;
        end
        hs = tf_dp2h(Ts,FARIn,d,Pb);%出口静焓
        if (hs > htin)
            hs = htin;
        end
        [~,Rg]=tfd2gammarRg(Ts,FARIn,d);%此处需要使用燃气的物性参数
        rhos = Pb * divby(Rg* Ts);%密度
        V = sqrtT(2 * (htin - hs));%出口速度
        Wout = 1*Area*rhos*V;
        
        if Wout>W
            left=Pb;
        else
            right=Pb;
        end
        i=i+1;
        if i>50    
            fprintf('传感器静压求解不收敛');
            Pb=P;
            V=1;
            rhos = Pb * divby(Rg* TtIn);%密度
            break;
        end
        if abs(Wout-W)<0.00001    
            break;
        end       
    end
end

