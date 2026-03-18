function [GasOut,ed]=Bend_Circular(GasIn,Pb,data)
data.GasIn=GasIn;
data.Pb=Pb;
if abs(data.GasIn.Pt-Pb)<1
    GasOut=data.GasIn;
    GasOut.W=0;
    ed=[];
    return
end
%
if data.Pb>data.GasIn.Pt
    fprintf('%s\n','弯头模块逆流')
    data.adverse=1;
    sign=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else
    data.adverse=0;
    sign=1;
end

opt.maxiter=500;
opt.tolfun=1e-4;
opt.tolx=1e-12;
%% 求临界背压
data.flag=0;
icount=1;imax=1000;
while 1
    x0=[rand];
    bounds=[0 1];
    FUN=@(x) funwrapper(@Bend_Circular_Body,x,data);
    try
        [xg, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            % xg=roundn(xg,-5);
            fprintf('%s%d%s\n','弯头模块计算临界背压已收敛, 共计',icount,'次(^_^)')
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('弯头模块计算临界背压无法收敛,需要Debug...')
    end
end
[~,edg]=Bend_Circular_Body(xg,data);
%% 求实际出口参数
if data.Pb<edg.PbCri
    fprintf('%s\n','弯头模块堵塞, 直接给出结果')
    GasOut.W=sign*edg.W;
    if data.adverse==0
        GasOut.Ma1=edg.Ma1;
        GasOut.Ma2=edg.Ma2;
        GasOut.Pt=edg.Pt2;
        GasOut.Ps=edg.PbCri;
    elseif data.adverse==1
        GasOut.Ma1=edg.Ma2;
        GasOut.Ma2=edg.Ma1;
        GasOut.Pt=data.GasIn.Pt;
        GasOut.Ps=edg.Ps1;
    end
    ed=edg;
else
    data.flag=1;
    icount=1;imax=1000;
    while 1
        x0=[rand rand];
        bounds=[0 1;0 1];
        FUN=@(x) funwrapper(@Bend_Circular_Body,x,data);
        try
            [xf, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                % xf=roundn(xf,-5);
                fprintf('%s%d%s\n','弯头模块已收敛, 共计',icount,'次(^_^)')
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('弯头模块无法收敛,需要Debug...')
        end
    end
    [~,edf]=Bend_Circular_Body(xf,data);
    GasOut.W=sign*edf.W;
    if data.adverse==0
        GasOut.Ma1=edf.Ma1;
        GasOut.Ma2=edf.Ma2;
        GasOut.Pt=edf.Pt2;
        GasOut.Ps=edf.Ps2;
    elseif data.adverse==1
        GasOut.Ma1=edf.Ma2;
        GasOut.Ma2=edf.Ma1;
        GasOut.Pt=data.GasIn.Pt;
        GasOut.Ps=edf.Ps1;
    end
    ed=edf;
end
end