function GasOut=CRC(GasIn,W,data)
%%
if W==0
    GasOut=GasIn;
    return
end

%%
data.GasIn=GasIn;
data.W=W*data.percentage;

cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;
omega_disk=data.RES/60*2*pi;

for i=1:data.Geo.N
    R1=(data.Geo.face{i,2}(2)+data.Geo.face{i,3}(2))/2;
    R2=(data.Geo.face{i,4}(2)+data.Geo.face{i,1}(2))/2;
    p12=distance_p(data.Geo.face{i,1},data.Geo.face{i,2});
    p23=distance_p(data.Geo.face{i,2},data.Geo.face{i,3});
    p34=distance_p(data.Geo.face{i,3},data.Geo.face{i,4});
    p41=distance_p(data.Geo.face{i,4},data.Geo.face{i,1});
    Rm=(R1+R2)/2;
    
    A1=2*pi*R1*p23*sin(data.Geo.theta(i,2));%第二条边为进口
    A2=2*pi*R2*p41*sin(data.Geo.theta(i,4));%第四条边为出口
    if i==1
        Pt1=data.GasIn.Pt;
        Tt1=data.GasIn.Tt;
        Swirl1=data.GasIn.Swirl;
    else
        Pt1=Pt2;
        Tt1=Tt2;
        Swirl1=Swirl2;
        
    end
    [~,Ts1,~,rho1,Vr1,~]=WcalcStat(Pt1,Tt1,W,A1,data);
    omega1=Swirl1/R1^2;
    dh=(p23+p41);
    
    Rew=rho1*abs(omega1-max(omega_disk))*Rm^2/mu;
    Rer=rho1*Vr1*dh/mu;
    roughness=1/2*(data.boundary.roughness(i,1)+data.boundary.roughness(i,3));
    if Rer<4000
        f_Darch=64/Rew;
    elseif Rer>=4000
        f_Darch=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;
    else
        fl=64/Rer;
        ft=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;
        por=(Rew-2000)/2000;
        f_Darch=por*ft+(1-por)*fl;
    end
    K=f_Darch*((p12+p34)/2)/dh;% Loss coefficient
    Pt2=Pt1-K*W^2/(2*rho1*A1);
    
    %% 传热过程
    A=abs(pi*R2^2-pi*R1^2);
    
    Tf_p=find(data.boundary.htt(i,:)==1);% position
    hT_p=find(data.boundary.htt(i,:)==0);% position
    n_Tf_p=length(Tf_p);
    n_hT_p=length(hT_p);
    
    Tot_Qcell=0;
    
    for ii=1:n_Tf_p %循环计算每一个面的换热量
        diff_T=data.boundary.Tf(i,Tf_p(ii))-Ts1;
        if n_Tf_p==1 && Tf_p(ii)==3
            ii=ii+1;
        end
        Pr=cp*mu/k;
        
        if Rew<4000
            Nu=0.664*Rew^0.5*Pr^0.333;
        elseif Rew>=4000
            Nu=0.023*Rew^0.8*Pr^0.4;
        end
        
        HTCi=Nu*k/Rm;
        
        Tf_Q=HTCi*A*diff_T;
        Tot_Qcell=Tot_Qcell+Tf_Q;
    end
    
    for ii=1:n_hT_p
        hT_Q=data.boundary.tH(i,hT_p(ii));
        Tot_Qcell=Tot_Qcell+hT_Q*A;
        HTCi=0;
        Nu=0;
    end
    
    Tt2=Tt1+Tot_Qcell/(W*cp);
    Ct_p=find(~isnan(data.boundary.htt(i,:)));
    %%
    CoreSR=omega1/max(omega_disk);
    Cf(1:data.Geo.N,:)=[0.063/Rew^0.2/CoreSR^-1.87 NaN 0.042/Rew^0.2/(1-CoreSR)^-1.35 NaN].*ones(data.Geo.N,4); % 转矩系数;
    rotor=find(data.boundary.type(i,:)==1);
    stator=find(data.boundary.type(i,:)==0);
    for ii=1:length(Ct_p)
        if length(rotor)==2
            ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;
        elseif length(stator)==2
            ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
        elseif Ct_p(ii)==rotor
            ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;
        elseif Ct_p(ii)==stator
            ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
        end
    end
    Tot_ti=sum(ti);
    Swirl2=(W*Swirl1+Tot_ti)/W;
end

GasOut.W=W;
GasOut.Pt=Pt2*data.percentage+GasIn.Pt*(1-data.percentage);
GasOut.Tt=Tt2*data.percentage+GasIn.Tt*(1-data.percentage);
GasOut.Swirl=Swirl2*data.percentage+GasIn.Swirl*(1-data.percentage);
end
