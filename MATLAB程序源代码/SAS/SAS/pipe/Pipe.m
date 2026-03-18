function [GasOut,ed]=Pipe(GasIn,Pb,data)
data.GasIn=GasIn;
data.Pb=Pb;
option=data.ST; %'compressible'或'incompressible'
%%
if abs(data.GasIn.Pt-data.Pb)<1
    GasOut=data.GasIn;
    GasOut.W=0;
    ed=[];
    return
end
%%
if data.Pb>data.GasIn.Pt
    fprintf('%s\n','Pipe逆流')
    data.adverse=1;
    sign=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else
    data.adverse=0;
    sign=1;
end
%%
R=data.Cons.R;
g=data.Cons.g;
gamma=data.Cons.gamma;
cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;
A=pi*(data.d/2)^2;
%假设出口临界
data.flag=0;
Ma2=1;
Tt2=data.GasIn.Tt;%无换热
Ps2=data.Pb;
Pt2=PMa2Pstar(Ps2,Ma2);
Ts2=TstarMa2T(Tt2,Ma2);

rhos2=Ps2/(R*Ts2);
Vg2=sqrt(gamma*R*Ts2); %出口截面音速
V2=Ma2*Vg2;
W=rhos2*V2*A;


%%
if strcmp(option,'incompressible')
    opt.maxiter=500;
    opt.tolfun=1e-6;
    opt.tolx=1e-12;
%     data.flag=0;
    icount=1;imax=1000;
    while 1
        x0=rrd(data.GasIn.Tt,max(data.Tw),1);%出口温度
        if data.GasIn.Tt>max(data.Tw)
            bounds=[max(data.Tw) data.GasIn.Tt];
        else
            bounds=[data.GasIn.Tt max(data.Tw)];
        end
        Cell=@Pipe_InComp_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [Tt2Cri, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                Tt2Cri=round(Tt2Cri,10);
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('Pipe计算临界进口总压未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edg1]=Pipe_InComp_Body(Tt2Cri,data);
    %%
    if edg1.Pt1<data.GasIn.Pt % 出口超临界
        fprintf('%s\n','管路出口临界')
        choke=1;
        opt.maxiter=500;
        opt.tolfun=1e-12;
        opt.tolx=1e-12;
        data.flag=1; % 出口超临界
        icount=1;imax=1000;
        while 1
            x0=[rrd(data.Pb,data.GasIn.Pt,1) rrd(data.GasIn.Tt,max(data.Tw),1)];
            bounds=[data.Pb data.GasIn.Pt];
            if data.GasIn.Tt>max(data.Tw)
                bounds(2,:)=[max(data.Tw) data.GasIn.Tt];
            else
                bounds(2,:)=[data.GasIn.Tt max(data.Tw)];
            end
            Cell=@Pipe_InComp_Body;
            FUN=@(y) funwrapper(Cell,y,data);
            try
                [PtbTtbCri, ithist]=broyden(FUN,x0,opt,bounds);
                if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                    icount=icount+1;
                else
                    PtbTtbCri=round(PtbTtbCri,10);
                        % fprintf('%s%d%s\n','管路模块计算临界背压已收敛, 共计',icount,'次(^_^)')
                    break
                end
            catch
                icount=icount+1;
            end
            if icount>imax
                error('管路模块计算临界背压未收敛..., 需要Debug...(o_o)')
            end
        end
        [~,edg2]=Pipe_InComp_Body(PtbTtbCri,data);
        GasOut.W=sign*edg2.W*data.Num;
        ed=edg2;
        if data.adverse==0
            GasOut.Ps=data.Pb;
            GasOut.Pt=edg2.Pt2;
            GasOut.Tt=edg2.Tt2;
        else
            GasOut.Ps=edg2.Ps1;
            GasOut.Pt=edg2.Pt1;
            GasOut.Tt=edg2.Tt1;
        end
    else % 出口亚临界
        choke=0;
        opt.maxiter=500;
        opt.tolfun=1e-12;
        opt.tolx=1e-12;
        data.flag=2;
        icount=1;imax=1000;
        while 1
            x0=[narrowX0(data.GasIn.Pt,data.Pb,1) rrd(data.GasIn.Tt,max(data.Tw),1)]; % Ma2=x(1);Tt2=x(2);
            bounds=[0 1];
            if data.GasIn.Tt>max(data.Tw)
                bounds(2,:)=[max(data.Tw) data.GasIn.Tt];
            else
                bounds(2,:)=[data.GasIn.Tt max(data.Tw)];
            end
            Cell=@Pipe_InComp_Body;
            FUN=@(y) funwrapper(Cell,y,data);
            try
                [Ma2, ithist]=broyden(FUN,x0,opt,bounds);
                if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                    icount=icount+1;
                else
                    Ma2=round(Ma2,10);
                        % fprintf('%s%d%s\n','管路模块迭代已收敛, 共计',icount,'次(^_^)')
                    break
                end
            catch
                icount=icount+1;
            end
            if icount>imax
                error('管路模块迭代未收敛..., 需要Debug...(o_o)')
            end
        end
        [~,edf]=Pipe_InComp_Body(Ma2,data);
        GasOut.W=sign*edf.W*data.Num;
        if data.adverse==0
            GasOut.Ps=data.Pb;
            GasOut.Pt=edf.Pt2;
            GasOut.Tt=edf.Tt2;
        else
            GasOut.Ps=edf.Ps1;
            GasOut.Pt=edf.Pt1;
            GasOut.Tt=edf.Tt1;
        end
        ed=edf;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(option,'compressible')
    opt.maxiter=500;
    opt.tolfun=1e-12;
    opt.tolx=1e-12;
    data.flag=0; % 出口临界
    icount=1;imax=1000;
    while 1
        if data.type==0 %管道壁面绝热
            x0=rrd(0.8*data.GasIn.Tt,data.GasIn.Tt,1);%管道出口总温Tt2
        else %管道壁面恒定温度
            x0=rrd(0.8*data.GasIn.Tt,max(data.Tw),1);
        end
        if data.GasIn.Tt>max(data.Tw)
            bounds=[max(data.Tw) 1.2*data.GasIn.Tt];
        else
            bounds=[0.8*data.GasIn.Tt max(data.Tw)];
        end
        Cell=@Pipe_Comp_Body;
        FUN=@(y) funwrapper(Cell,y,data);
        try
            [Tt2Cri, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                Tt2Cri=round(Tt2Cri,10);
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            error('Pipe计算临界进口总压未收敛..., 需要Debug...(o_o)')
        end
    end
    [~,edg1]=Pipe_Comp_Body(Tt2Cri,data);
    %%
    if edg1.Pt(end)<data.GasIn.Pt
        fprintf('%s\n','管路堵塞')
        choke=1;
        opt.maxiter=500;
        opt.tolfun=1e-12;
        opt.tolx=1e-12;
        data.flag=1;
        icount=1;imax=1000;
        while 1
            x0=[rrd(data.Pb,data.GasIn.Pt,1) rrd(0.8*data.GasIn.Tt,max(data.Tw),1)];
            bounds=[data.Pb data.GasIn.Pt];
            if data.GasIn.Tt>max(data.Tw)
                bounds(2,:)=[max(data.Tw) 1.2*data.GasIn.Tt];
            else
                bounds(2,:)=[0.8*data.GasIn.Tt max(data.Tw)];
            end
            Cell=@Pipe_Comp_Body;
            FUN=@(y) funwrapper(Cell,y,data);
            try
                [PtbTtbCri, ithist]=broyden(FUN,x0,opt,bounds);
                if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                    icount=icount+1;
                else
                    PtbTtbCri=round(PtbTtbCri,10);
                        % fprintf('%s%d%s\n','管路模块计算临界背压已收敛, 共计',icount,'次(^_^)')
                    break
                end
            catch
                icount=icount+1;
            end
            if icount>imax
                error('管路模块计算临界背压未收敛..., 需要Debug...(o_o)')
            end
        end
        [~,edg2]=Pipe_Comp_Body(PtbTtbCri,data);
        GasOut.W=sign*edg2.W*data.Num;
        ed=edg2;
        if data.adverse==0
            GasOut.Ps=data.Pb;
            GasOut.Pt=edg2.Pt(1);
            GasOut.Tt=edg2.Tt(1);
        else
            GasOut.Pt=data.GasIn.Pt;
            GasOut.Ps=edg2.Ps(end);
            GasOut.Tt=edg2.Tt(end);
        end
    else
        choke=0;
        opt.maxiter=500;
        opt.tolfun=1e-12;
        opt.tolx=1e-12;
        data.flag=2;
        icount=1;imax=1000;
        while 1
            x0=[rand rrd(0.8*data.GasIn.Tt,max(data.Tw),1)];%(data.Pb+data.GasIn.Pt)/2;
            bounds=[0 1];
            if data.GasIn.Tt>max(data.Tw)
                bounds(2,:)=[max(data.Tw) 1.2*data.GasIn.Tt];
            else
                bounds(2,:)=[0.8*data.GasIn.Tt max(data.Tw)];
            end
            Cell=@Pipe_Comp_Body;
            FUN=@(y) funwrapper(Cell,y,data);
            try
                [Ma2, ithist]=broyden(FUN,x0,opt,bounds);
                if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                    icount=icount+1;
                else
                    Ma2=round(Ma2,10);
                        % fprintf('%s%d%s\n','管路模块迭代已收敛, 共计',icount,'次(^_^)')
                    break
                end
            catch
                icount=icount+1;
            end
            if icount>imax
                error('管路模块迭代未收敛..., 需要Debug...(o_o)')
            end
        end
        [~,edf]=Pipe_Comp_Body(Ma2,data);
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
end
GasOut.Swirl=GasIn.Swirl;
end