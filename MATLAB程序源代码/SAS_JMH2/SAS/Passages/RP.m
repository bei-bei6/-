function [GasOut,ed]=RP(GasIn,Pb,data)
data.GasIn=GasIn;
data.Pb=Pb;
%%
if abs(data.GasIn.Pt-data.Pb)<1
    GasOut=data.GasIn;
    GasOut.W=0;
    ed=[];
    return
end
%%
if data.Pb>data.GasIn.Pt
    fprintf('%s\n','旋转通道逆流')
    data.adverse=1;
    sign=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else
    data.adverse=0;
    sign=1;
end
%%
opt.maxiter=500;
opt.tolfun=1e-12;
opt.tolx=1e-12;

data.flag=0;
icount=1;imax=1000;
while 1
    x0=rrd(data.GasIn.Tt,max(data.Tw),1);
    if data.GasIn.Tt>max(data.Tw)
        bounds=[max(data.Tw) 1.2*data.GasIn.Tt];
    else
        bounds=[0.8*data.GasIn.Tt max(data.Tw)];
    end
    Cell=@RP_Body;
    FUN=@(y) funwrapper(Cell,y,data);
    try
        [Tt2Cri, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            Tt2Cri=roundn(Tt2Cri,-10);
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('旋转通道模块计算临界进口总压未收敛..., 需要Debug...(o_o)')
    end
end
[~,edg1]=RP_Body(Tt2Cri,data);
%%
if edg1.Pt(end)<data.GasIn.Pt
    fprintf('%s\n','旋转通道堵塞')
    choke=1;
    opt.maxiter=500;
    opt.tolfun=1e-12;
    opt.tolx=1e-12;
    data.flag=1;
    icount=1;imax=1000;
    while 1
        x0=[rrd(data.Pb,data.GasIn.Pt,1) rrd(data.GasIn.Tt,max(data.Tw),1)];
%         bounds=[data.Pb data.GasIn.Pt];
        if data.GasIn.Tt>max(data.Tw)
            bounds(2,:)=[max(data.Tw) 1.2*data.GasIn.Tt];
        else
            bounds(2,:)=[0.8*data.GasIn.Tt max(data.Tw)];
        end
        Cell=@RP_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
%             if rand>0.5
%                 [PtbTtbCri, ithist]=broyden(FUN,x0,opt,bounds);
%             else
                [PtbTtbCri, ithist]=broyden(FUN,x0,opt);
%             end
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                PtbTtbCri=roundn(PtbTtbCri,-10);
                fprintf('%s%d%s\n','旋转通道模块计算临界背压已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('旋转通道模块计算临界背压未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edg2]=RP_Body(PtbTtbCri,data);
    GasOut.W=sign*edg2.W*data.Num;
    if data.adverse==0
        GasOut.Ps=data.Pb;
        GasOut.Pt=edg2.Pt(1);
        GasOut.Tt=edg2.Tt(1);
    else
        GasOut.Pt=data.GasIn.Pt;
        GasOut.Ps=edg2.Ps(end);
        GasOut.Tt=edg2.Tt(end);
    end
    ed=edg2;
else
    choke=0;
    opt.maxiter=500;
    opt.tolfun=1e-12;
    opt.tolx=1e-12;
    data.flag=2;
    icount=1;imax=1000;
    while 1
        x0=[narrowX0(data.GasIn.Pt,data.Pb,1) rrd(data.GasIn.Tt,max(data.Tw),1)];%(data.Ptb+data.GasIn.Pt)/2;
        bounds=[0 0.999];
        if data.GasIn.Tt>max(data.Tw)
            bounds(2,:)=[max(data.Tw) 1.2*data.GasIn.Tt];
        else
            bounds(2,:)=[0.8*data.GasIn.Tt max(data.Tw)];
        end
        Cell=@RP_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [Ma2, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                Ma2=roundn(Ma2,-10);
                fprintf('%s%d%s\n','旋转通道模块迭代已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('旋转通道模块迭代未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edf]=RP_Body(Ma2,data);
    GasOut.W=sign*edf.W*data.Num;
    if data.adverse==0
        GasOut.Ps=edf.Ps(1);
        GasOut.Pt=edf.Pt(1);
        GasOut.Tt=edf.Tt(1);
    else
        GasOut.Ps=edf.Ps(end);
        GasOut.Pt=edf.Pt(end);
        GasOut.Tt=edf.Tt(end);
    end
    ed=edf;
end
%% 出口角动量
r1=sqrt(data.Node1.y^2+data.Node1.z^2);
r2=sqrt(data.Node2.y^2+data.Node2.z^2);
if data.RES==0 || (r1==0 && r2==0)
    GasOut.Swirl=0;
else
    w=2*pi*(data.RES/60);
    GasOut.Swirl=w*r2^2;
end
ed.choke=choke;
end
