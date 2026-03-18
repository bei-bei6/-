function [NErr,ed]=blade_Body(x,data)
delta_tbc=data.delta_tbc;%热障涂层厚度
k_tbc=data.k_tbc; %热障涂层导热系数
delta_bw=data.delta_bw;%叶片壁面厚度
k_bw=data.k_bw;
hg=data.hg; %燃气对流换热系数
eta_c=data.eta_c;
eta_f=data.eta_f;
cpg=data.Cons.cpg;
cpc=data.Cons.cp;
Ath=data.Ath;%涡轮叶片喉道面积
Ag=data.Ag;%叶片外表面积

epsilon_c=x;
%
Wc=data.Wc; %根据绝热壁面条件计算得到的冷气流量
Wg=data.GasPrimary.W;%主燃流量
Tg=data.GasPrimary.Tt;%主燃温度

Ttin=data.GasIn.Tt;
Tb=Tg-epsilon_c*(Tg-Ttin);
Tc_out=eta_c*(Tb-Ttin)+Ttin;
Tf=Tg-eta_f*(Tg-Tc_out);
Bi_tbc=hg*delta_tbc/k_tbc;
Bi_bw=hg*delta_bw/k_bw;
%
if Wc==0
    return
end
%
Stg=hg/((Wc/Ath)*cpg);
Kc=Stg*(cpg/cpc)*(Ag/Ath);
Bi_total=Bi_tbc-((epsilon_c-eta_f)/(1-epsilon_c))*Bi_bw;
NErr=Wc/Wg-Kc/(1+Bi_total)*(epsilon_c-eta_f*(1-eta_c*(1-epsilon_c)))/(eta_c*(1-epsilon_c));

ed.Tb=Tb;
ed.Tf=Tf;
ed.epsilon_c=epsilon_c;
ed.Kc=Kc;
ed.Bi_total=Bi_total;
ed.Tc_out=Tc_out;
end