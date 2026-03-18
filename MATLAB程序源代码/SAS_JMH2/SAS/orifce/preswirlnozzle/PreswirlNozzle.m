function [GasOut,ed]=PreswirlNozzle(GasIn,Psout,data) %Psout为设定的预旋喷嘴出口压力（待修改）；
gamma=data.Cons.gamma;
data.Psout=Psout;%data.Psout和Psout均为设定的预旋喷嘴出口压力；（设定=Pcr）
if abs(data.Psout-GasIn.Pt)<1e-3
    GasOut.W=0;
    ed=[];
    return
end
if data.Psout>GasIn.Pt % 检查是否存在逆流
    [GasIn,data.Psout]=swap(GasIn,data.Psout);
    adverse=-1;
else
    adverse=1;
end
% 计算临界压比（非等熵，需要迭代计算）
data.choke=1;
data.GasIn=GasIn;
opt.maxiter=500;
opt.tolfun=1e-8;
opt.tolx=1e-12;
icount=1;imax=1000;
while 1
    x0=[rand PstarMa2P(data.GasIn.Pt,1)];%迭代初值=[入口Ma=rand，出口压力=Pcr]
    bounds=[0 1;0 data.GasIn.Pt];
    FUN=@(x) funwrapper(@PreswirlNozzle_Body,x,data);%FUN(x)=PreswirlNozzle_Body(x,data);待求参数x:x(1)=Ma1,x(2)=Psout;
    try
        [x, ithist]=broyden(FUN,x0,opt,bounds);%求解FUN(x)=PreswirlNozzle_Body(x,data)
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            x=round(x,7);
            break %输出迭代求解的x(1),x(2);
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        fprintf('%s\n','计算预旋喷嘴临界压比未收敛..., 需要Debug...(o_o)')
        return
    end
end
if Psout<x(2) %计算得到的出口压力x(2)＞设定的出口压力Psout（=Pcr）时，说明设定的Psout＜临界压力Pcr，超临界。
    fprintf('%s\n','预旋喷嘴喉道临界')
    [~,ed]=PreswirlNozzle_Body(x,data);
else
    data.choke=0;
    while 1
        x0=[rand PstarMa2P(data.GasIn.Pt,1)];
        bounds=[0 1;0 data.GasIn.Pt];
        FUN=@(x) funwrapper(@PreswirlNozzle_Body,x,data);
        try
            [x, ithist]=broyden(FUN,x0,opt,bounds);
            if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
                icount=icount+1;
            else
                x=round(x,7);
                break
            end
        catch
            icount=icount+1;
        end
        if icount>imax
            fprintf('%s\n','预旋喷嘴计算未收敛..., 需要Debug...(o_o)')
            return
        end
    end
    [~,ed]=PreswirlNozzle_Body(x,data);
end

GasOut.W=adverse*ed.W*data.Num;
GasOut.Tt=GasIn.Tt;
GasOut.Ps=ed.Ps2;
GasOut.Ts=ed.Ts2;
GasOut.Swirl=ed.Swirl;
GasOut.Pt=ed.Pt2;
end