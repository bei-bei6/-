function [GasOut,ed]=DL(GasIn,Psout,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
Radius=data.D/2;
A=pi*Radius^2;

data.GasIn=GasIn;
data.Psout=Psout;

if abs(data.Psout-GasIn.Pt)<1e-3
    GasOut.W=0;
    ed=[];
    return
end

if data.Psout>data.GasIn.Pt
    data.adverse=-1;
    [data.GasIn,data.Psout]=swap(data.GasIn,data.Psout);
else
    data.adverse=1;
end

Ma=0.001:0.001:1;
DMa=X(Ma);
% 假设堵塞
Ma1e=interp1Ac_SAS(DMa,Ma,data.flc*double(data.adverse>0)+data.rlc*double(data.adverse<0),length(Ma));
We=(gamma^0.5*Ma1e/(1+(gamma-1)*Ma1e^2/2)^((gamma+1)/(2*(gamma-1)))*A)*data.GasIn.Pt/(R*data.GasIn.Tt)^0.5;
Ma2e=1;
Pt2=We*(R*data.GasIn.Tt)^0.5/(gamma^0.5*Ma2e/(1+(gamma-1)*Ma2e^2/2)^((gamma+1)/(2*(gamma-1)))*A);
Ps2g=PstarMa2P(Pt2,1);
Ps1g=PstarMa2P(data.GasIn.Pt,Ma1e);

if data.Psout<Ps2g %确实堵塞
    GasOut.W=data.adverse*We*data.Num;
    if data.adverse==1
        GasOut.Ma1=Ma1e;
        GasOut.Ma2=1;
        GasOut.Ps=data.Psout;
        GasOut.Pt=Pt2;
    elseif data.adverse==-1
        GasOut.Ma1=1;
        GasOut.Ma2=Ma1e;
        GasOut.Ps=Ps1g;
        GasOut.Pt=data.GasIn.Pt;
    end
    GasOut.Tt=GasIn.Tt;
    GasOut.Swirl=GasIn.Swirl;
    ed=[];
else
    icount=0;imax=500;
    while 1
        x0=narrowX0(GasIn.Pt,Psout,2);
        bounds=[0 1;0 1];
        opt.maxiter=500;
        opt.tolfun=1e-8;
        opt.tolx=1e-12;
        Cell=@DL_Comp_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [Ma12, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                Ma12=round(Ma12,7);
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            fprintf('%s\n','DL无法收敛,需要Debug...')
            return
        end
    end
    
    [~,ed]=DL_Comp_Body(Ma12,data);
    GasOut.W=data.adverse*ed.W*data.Num;
    if data.adverse==1
        GasOut.Ma1=Ma12(1);
        GasOut.Ma2=Ma12(2);
        GasOut.Ps=data.Psout;
        GasOut.Pt=ed.Pt2;
    elseif data.adverse==-1
        GasOut.Ma1=Ma12(2);
        GasOut.Ma2=Ma12(1);
        GasOut.Ps=ed.Ps1;
        GasOut.Pt=data.GasIn.Pt;
    end
    GasOut.Tt=GasIn.Tt;
    GasOut.Swirl=GasIn.Swirl;
end
end