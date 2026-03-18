function [GasOut,ed]=blade(GasIn,GasPrimary,Psout,data)
% 计算冷却气流量
[adiabaticflow,adiabaticflow_ed]=Pipe(GasIn,Psout,data);%算绝热壁面bc的冷气流量
data.Wc=adiabaticflow.W;
% 传热计算
%{
opt.maxiter=500;
opt.tolfun=1e-8;
opt.tolx=1e-12;
data.GasIn=GasIn;
data.GasPrimary=GasPrimary;%主燃温度，主燃流量
data.Psout=Psout;
icount=1;imax=1000;
while 1
    epsilon_c0=rrd(0,1,1);%气膜绝热有效度_初始值
    bounds=[0 1];
    FUN=@(x) funwrapper(@blade_Body,x,data);
    try
        [epsilon_c, ithist]=broyden(FUN,epsilon_c0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            epsilon_c=round(epsilon_c,7);
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('叶片计算epsilon_c未收敛..., 需要Debug...(o_o)')
    end
end
[~,ed]=blade_Body(epsilon_c,data);
GasOut.W=data.Wc;
GasOut.Tt=ed.Tc_out;
GasOut.Pt=adiabaticflow.Pt;
GasOut.Swirl=GasIn.Swirl;
ed.MeshGasPar=adiabaticflow_ed;
%}
GasOut.W=data.Wc;
GasOut.Ps=adiabaticflow.Ps;
GasOut.Pt=adiabaticflow.Pt;
GasOut.Tt=adiabaticflow.Tt;
GasOut.Swirl=adiabaticflow.Swirl;
ed=GasOut;
end