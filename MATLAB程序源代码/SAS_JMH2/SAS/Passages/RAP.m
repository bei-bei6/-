function [GasOut,ed]=RAP(GasIn,Pb,data)% Rotating Annular Passage
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
    fprintf('%s\n','环形旋转通道逆流')
    data.adverse=1;
    sign=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else 
    data.adverse=0;
    sign=1;
end
%%
opt.maxiter=500;% maximum number of iterations
opt.tolfun=1e-5;% Function tolerance, Iterations end if ||F(x)||_2 < tolfun
opt.tolx=1e-12; % Step length tolerance, Newton's method stops if ||Newton step||_2 < tolx

data.flag=0;%【出口临界】
icount=1;imax=1000;
while 1
    x0=rrd(data.GasIn.Tt,max(data.Two),1);%初值x0为区间[GasIn.Tt,data.Two]中任意值
    if data.GasIn.Tt>max(data.Two)
        bounds=[max(data.Two) 1.2*data.GasIn.Tt];
    else
        bounds=[0.8*data.GasIn.Tt max(data.Two)];
    end
    Cell=@RAP_Body;
    FUN=@(y) funwrapper(Cell,y,data);%  FUN=@(y) funwrapper(Cell,y,data)；FUN(y)=Cell(y,data)=RAP_Body(y,data)
    try
        [Tt2Cri, ithist]=broyden(FUN,x0,opt,bounds);% 求解RAP_Body函数，得到Tt2Cri: approximation of the solution.
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            Tt2Cri=round(Tt2Cri,10);%将Tt2Cri四舍五入到最接近10^-10的倍数
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('环形旋转通道模块计算临界进口总压未收敛..., 需要Debug...(o_o)')
    end
end
[~,edg1]=RAP_Body(Tt2Cri,data);%Tt2Cri：出口总温；edg1包括出口马赫数，出口总压，出口两个node间的总温分布，流量，旋转雷诺数
%%
if edg1.Pt(end)<data.GasIn.Pt
    fprintf('%s\n','环形旋转通道堵塞')
    choke=1;
    opt.maxiter=500;
    opt.tolfun=1e-5;
    opt.tolx=1e-12;
    data.flag=1;%
    icount=1;imax=1000;
    while 1
        x0=[rrd(data.Pb,data.GasIn.Pt,1) rrd(data.GasIn.Tt,max(data.Two),1)];%(data.Pb+data.GasIn.Pt)/2;
        bounds=[data.Pb data.GasIn.Pt];
        if data.GasIn.Tt>max(data.Two)
            bounds(2,:)=[max(data.Two) 1.2*data.GasIn.Tt];
        else
            bounds(2,:)=[0.8*data.GasIn.Tt max(data.Two)];
        end
        Cell=@RAP_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [PtbTtbCri, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                PtbTtbCri=round(PtbTtbCri,10);
                fprintf('%s%d%s\n','环形旋转通道模块计算临界背压已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('环形旋转通道模块计算临界背压未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edg2]=RAP_Body(PtbTtbCri,data);
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
    opt.tolfun=1e-5;
    opt.tolx=1e-12;
    data.flag=2;
    icount=1;imax=1000;
    while 1
        x0=[narrowX0(data.GasIn.Pt,data.Pb,1) rrd(data.GasIn.Tt,max(data.Two),1)];%(data.Pb+data.GasIn.Pt)/2;
        bounds=[0 0.999];
        if data.GasIn.Tt>max(data.Two)
            bounds(2,:)=[max(data.Two) 1.2*data.GasIn.Tt];
        else
            bounds(2,:)=[0.8*data.GasIn.Tt max(data.Two)];
        end
        Cell=@RAP_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [Ma2, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                Ma2=round(Ma2,10);
                fprintf('%s%d%s\n','环形旋转通道模块迭代已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('环形旋转通道模块迭代未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edf]=RAP_Body(Ma2,data);
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
%% 计算出口旋流比
data.Rew=ed.Rew;
if data.RESO==0 && data.RESI==0
    GasOut.Swirl=data.GasIn.Swirl;
else
    data.GasOut=GasOut;
    icount=1;imax=1000;
    while 1
        x0=rrd(0,(2*pi*(data.RESI/60)+2*pi*(data.RESO/60))/2,1);%旋转角速度
        bounds=[0 GasIn.Swirl/((data.d1/2+data.d2/2)/2)^2+2*pi*(data.RESI/60)+2*pi*(data.RESO/60)];
        Cell=@RAP_Swirl;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [SwirlOut, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                SwirlOut=round(SwirlOut,10);
                fprintf('%s%d%s\n','环形旋转通道模块计算出口角动量已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('环形旋转通道模块计算出口角动量未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,ExitSwirlData]=RAP_Swirl(SwirlOut,data);
    if data.adverse==0
        GasOut.Swirl=ExitSwirlData.Swirl2;
    else
        GasOut.Swirl=data.GasIn.Swirl;
    end
end
end