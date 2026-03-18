function [y,ed]=LSST_Implicit_Body(x,data)
R=data.Cons.R;
gamma=data.Cons.gamma;

Pt(data.NT-1)=x;
Pt(data.NT)=data.Pb;
b=1-((gamma+1)/2)^(-2*gamma/(gamma-1));%ʽ3.27
for i=data.NT:-1:1
    if i~=1
        mu=1+0.0791*(data.NT-1); %ʽ3.12
    elseif i==1
        mu=1;
    end
    if i==data.NT
        S(i)=(Pt(i-1)/Pt(i))^((gamma-1)/gamma)-1;
        if data.choked==1
            W=Pt(data.NT-1)*pi*sqrt(b)/(pi+5+0.5*gamma^2-3.5*gamma)*mu*data.ANAR/sqrt(R*data.GasIn.Tt); %ʽ3.44
        elseif data.choked==0
            W=pi*Pt(i)/(pi+2-5*S(i)+2*(S(i))^2)*sqrt((S(i)+1)^(2*gamma/(gamma-1))-1)*mu*data.ANAR/sqrt(R*data.GasIn.Tt); %ʽ3.38
        end
    else
        if data.choked==1
            S(i)=secant(@(x) W-pi*Pt(i)/(pi+2-5*x+2*x^2)*sqrt((x+1)^(2*gamma/(gamma-1))-1)*mu*data.ANAR/sqrt(R*data.GasIn.Tt),0,10,1e-6,500);
        elseif data.choked==0
            S(i)=secant(@(x) W-pi*Pt(i)/(pi+2-5*x+2*x^2)*sqrt((x+1)^(2*gamma/(gamma-1))-1)*mu*data.ANAR/sqrt(R*data.GasIn.Tt),0,10,1e-6,500);
        end
        S(i)=real(S(i));
        if i~=1
            Pt(i-1)=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
        else
            Pt0=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
        end
    end
end
y=Pt0-data.GasIn.Pt;
ed.W=W;
ed.Pt=Pt;
ed.Pt0=Pt0;
ed.S=S;
end