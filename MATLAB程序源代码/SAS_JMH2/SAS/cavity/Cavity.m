function [GasOut,ed]=Cavity(GasIn,Pb,data)
%该程序可以计算一般腔的可压缩腔流动
gamma=data.Cons.gamma;
R=data.Cons.R;
mu=data.Cons.mu;
cp=data.Cons.cp;
k=data.Cons.k; % thermal conductivity
Pr=data.Cons.Pr;

data.GasIn=GasIn;
data.Pb=Pb;
Pt1=GasIn.Pt;
Tt1=GasIn.Tt;

count_rotwall=sum(data.boundary.type==1) ; % 旋转壁面边界总数
data.omega_ref=max(abs(data.boundary.RES))*2*pi/60; % 参考转子角速度,rad/s

if data.direction == 1 % data.direction:1从下至上，-1为从上至下
    data.Rin=data.Geo.PosL; % 入口半径
    data.Rout=data.Geo.PosH; % 出口半径
    data.AI=2*pi*data.Geo.PosL*data.Geo.G; % 入口面积
    data.AO=2*pi*data.Geo.PosH*data.Geo.G; % 出口面积
elseif data.direction == -1
    data.Rin=data.Geo.PosH; % 入口半径
    data.Rout=data.Geo.PosL; % 出口半径
    data.AI=2*pi*data.Geo.PosH*data.Geo.G; % 入口面积
    data.AO=2*pi*data.Geo.PosL*data.Geo.G; % 出口面积
end

%%
opt.maxiter=500;
opt.tolfun=1e-6;
opt.tolx=1e-12;
icount=1;imax=1000;
while 1
    x0=rand; %入口马赫数
    bounds=[0 1];
    Cell=@Cavity_newbody;
    FUN=@(x) funwrapper(Cell,x,data);
    try
        [x, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
            icount=icount+1;
        else
            x=round(x,10);
            fprintf('%s%d%s\n','Cavity模块计算已收敛, 共计',icount,'次(^_^)')
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('Cavity模块计算未收敛..., 需要Debug...(o_o)')
    end
end
[Nerr,ed]=Cavity_newbody(x,data);
%% 输出参数
GasOut.W=ed.W;
GasOut.Tt=ed.Tt2; %Tt1=Tt2（绝能流动总温守恒）
GasOut.Ps=ed.Ps2;
GasOut.Pt=ed.Pt2;
GasOut.Ts=ed.Ts2;
GasOut.Sf=ed.Sf2;
GasOut.Swirl=ed.Swirl2;%涡参数 Swirl=omega_air*r^2
end