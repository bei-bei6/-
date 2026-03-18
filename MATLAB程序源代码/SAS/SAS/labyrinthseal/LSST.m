function [GasOut,ed]=LSST(GasIn,Pb,data)
%% ¹«Ê½ÒýÓÃ×ÔÎÄÏ×¡±Leakage and swirl velocities in labyrinth seals, U?gur Y¨¨ucel, Lehigh University¡°
R=data.Cons.R;
gamma=data.Cons.gamma;
data.GasIn=GasIn;
data.Pb=Pb;

if strcmp(data.Pos,'Rotor')
    data.ANAR=pi*(2*(data.Rsi+data.Bi)+data.Cri)*data.Cri;
    data.asi=1;
    data.ari=(2*data.Bi+data.Li)/data.Li;
elseif strcmp(data.Pos,'Stator')
    data.ANAR=pi*(2*(data.Rsi)+data.Cri)*data.Cri;
    data.asi=(2*data.Bi+data.Li)/data.Li;
    data.ari=1;
end
%% METHOD
Method_C=1;
Method_mu=1;
%
if data.Pb>data.GasIn.Pt
    fprintf('%s\n','ó÷³ÝÄæÁ÷')
    data.adverse=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else
    data.adverse=1;
end
switch data.Method
    case 'explicit'
        switch Method_C
            case 1
                C0=pi/(pi+2);% Ê½3.7
            case 2
                C0=0.716;% Ê½3.8
        end
        switch Method_mu
            case 1
                mu=1+0.0791*(data.NT-1);
        end
        b=1-((gamma+1)/2)^(-2*gamma/(gamma-1));%Ê½3.27
        rc=((gamma+1)/2)^(gamma/(gamma-1))*sqrt(b*mu^2+b*(data.NT-2)+1);%Ê½3.33
        if data.GasIn.Pt/data.Pb<rc
            fprintf('%s\n','ó÷³ÝÎ´¶ÂÈû')
            W=C0*data.ANAR*sqrt(data.GasIn.Pt^2-data.Pb^2)/sqrt(R*data.GasIn.Tt*(1+(data.NT-1)/mu^2));
            k=sqrt((data.GasIn.Pt^2-data.Pb^2)/(1+(data.NT-1)/mu^2));
            Pt(data.NT)=data.Pb;
            for i=data.NT:-1:2
                Pt(i-1)=sqrt((Pt(i))^2+k^2/mu^2);
                S(i)=(Pt(i-1)/Pt(i))^((gamma-1)/gamma)-1;
            end
            Pt0=data.GasIn.Pt;
            S(1)=(Pt0/Pt(1))^((gamma-1)/gamma)-1;
            GasOut.W=data.adverse*W;
            GasOut.Pt=Pt(end);
            % GasOut.Tt=GasIn.Tt;
            ed.Pt=Pt;
            ed.S=S;
        else
            fprintf('%s\n','ó÷³Ý¶ÂÈû')
            k=sqrt(data.GasIn.Pt^2/(1+(data.NT-2)/mu^2+1/(b*mu^2)));
            W=C0*data.ANAR*data.GasIn.Pt*sqrt(1/(1+(data.NT-2)/mu^2+1/(b*mu^2)))/sqrt(R*data.GasIn.Tt);
            Pt(data.NT-1)=k/(mu*sqrt(b));
            for i=data.NT-1:-1:2
                Pt(i-1)=sqrt((Pt(i))^2+k^2/mu^2);
                S(i)=(Pt(i-1)/Pt(i))^((gamma-1)/gamma)-1;
            end
            Pt0=data.GasIn.Pt;
            S(1)=(Pt0/Pt(1))^((gamma-1)/gamma)-1;
            GasOut.W=data.adverse*W;
%             GasOut.Ps=data.Pb;
            GasOut.Pt=Pt(end);
            % GasOut.Tt=GasIn.Tt;
            ed.Pt=Pt;
        end
        [V,taur,taus]=LSST_Circumferential_Vec(W,S,data);
        GasOut.Swirl=V(end)*data.Rsi;
        ed.V=V;
    case 'implicit' %²ÉÓÃ¸ü¸´ÔÓµÄ¸ñÊ½
        %%
        Pt(data.NT)=data.Pb;
        Pt(data.NT-1)=Pt(data.NT)*((gamma+1)/2)^(gamma/(gamma-1)); %Ê½3.41 ¼ÙÉèó÷³Ý¶ÂÈû
        b=1-((gamma+1)/2)^(-2*gamma/(gamma-1)); %Ê½3.27
        for i=data.NT:-1:1
            if i~=1
                mu=1+0.0791*(data.NT-1); %Ê½3.12
            elseif i==1
                mu=1;
            end
            if i==data.NT
                S(i)=(Pt(i-1)/Pt(i))^((gamma-1)/gamma)-1;
                W=Pt(data.NT-1)*pi*sqrt(b)/(pi+5+0.5*gamma^2-3.5*gamma)*mu*data.ANAR/sqrt(R*data.GasIn.Tt); %Ê½3.44
            else
                S(i)=secant(@(x) W-pi*Pt(i)/(pi+2-5*x+2*x^2)*sqrt((x+1)^(2*gamma/(gamma-1))-1)*mu*data.ANAR/sqrt(R*data.GasIn.Tt),0,10,1e-6,500);
                S(i)=real(S(i));
                if i~=1
                    Pt(i-1)=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
                else
                    Pt0=Pt(i)*(S(i)+1)^(gamma/(gamma-1));
                end
            end
        end
        %
        if Pt0<=data.GasIn.Pt
            data.choked=1; %ó÷³Ý¶ÂÈû
            fprintf('%s\n','ó÷³Ý¶ÂÈû')
        else
            data.choked=0; %ó÷³ÝÎ´¶ÂÈû
            fprintf('%s\n','ó÷³ÝÎ´¶ÂÈû')
        end
        FUN=@(x) funwrapper(@LSST_Implicit_Body,x,data);
        PNT_1 = secant(FUN,data.Pb,data.GasIn.Pt,1e-6,500);
        [~,ed_impicit]=LSST_Implicit_Body(PNT_1,data);
        GasOut.W=ed_impicit.W;
        GasOut.Pt=ed_impicit.Pt(end);
        % GasOut.Tt=GasIn.Tt;
        [V,taur,taus]=LSST_Circumferential_Vec(ed_impicit.W,ed_impicit.S,data);
        GasOut.Swirl=V(end)*data.Rsi;
        ed=ed_impicit;
        ed.V=V;
end
GasOut.Ps=data.Pb;
%% 

GasOut.Tt=GasIn.Tt;
end

