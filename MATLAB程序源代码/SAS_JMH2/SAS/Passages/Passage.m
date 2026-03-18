function [GasOut,ed]=Passage(GasIn,Pb,data)%旋转通道模型方程
%该程序可以计算等截面旋转通道的可压缩流动
% 判断流动状态
if Pb-GasIn.Pt>1e-3
    disp('Passage单元发生逆流')
    [GasIn,Pb]=swap(GasIn,Pb);
    adverse=-1;
elseif abs(Pb-GasIn.Pt)<=1e-3
    GasOut.W=0;
    ed=[];
    return;  %不再向下执行Duct函数
else
    adverse=1;
end

htt=data.CaseOpt.htt;
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

data.D=data.d2-data.d1; % 当量直径Dh=4A/P
data.A=pi/4*(data.d2^2-data.d1^2);%环隙面积
data.A1=data.A; data.A2=data.A;
data.AwI=pi*data.d1*data.L;%内壁面侧表面积
data.AwO=pi*data.d2*data.L;%外壁面侧表面积
%% 计算流量初值 （最大流量：等熵流动，出口马赫数为1）
PI=Pt1/Pb; %落压比：进口总压与反压之比
PI_cr=((gamma+1)/2)^(gamma/(gamma-1));%临界压比，空气(k=1.4) Pt/Pcr=1.8929
P_cr=Pt1/PI_cr; %临界压力
if PI < PI_cr %亚临界流动状态
    data.choke=0; %未壅塞
    %disp('Passage单元亚临界')
    Ps2=Pb;
    Ts2=Tt1/(Pt1/Ps2)^((gamma-1)/gamma);
    Ma2=TstarT2Ma(Tt1,Ts2);
else PI >= PI_cr %临界及超临界流动状态
    data.choke=1; %壅塞
    %fprintf('%s\n','Passage出口壅塞')
    Ps2=P_cr;
    Ma2=1;
    Ts2=TstarMa2T(Tt1,Ma2);
end
Pt2=PMa2Pstar(Ps2,Ma2);
rhos2=Ps2/(R*Ts2);
c2=sqrt(gamma*R*Ts2);
V2=Ma2*c2;
W_id=rhos2*V2*data.A2;%理想流量（等熵流动）
W=W_id;
W_max=Ps2*data.A2*sqrt(gamma*((gamma+1)/2))/sqrt(R*Tt1); %最大流量（等熵流动，出口马赫数为1）
data.Ps2=Ps2;
%%
opt.maxiter=2000;
opt.tolfun=1e-8;
opt.tolx=1e-12;
icount=1;imax=1000;
while 1
    x0=W;
    bounds=[0 W_max];
    Cell=@Passage_Body;
    FUN=@(x) funwrapper(Cell,x,data);
    try
        [W, ithist]=broyden(FUN,x0,opt,bounds);
        if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))%ithist.normf：函数误差（NErr）
            icount=icount+1;
        else
            W=round(W,10);
            fprintf('%s%d%s\n','Passage模块计算已收敛, 共计',icount,'次(^_^)')
            break
        end
    catch
        icount=icount+1;
    end
    if icount>imax
        error('Passage模块计算未收敛..., 需要Debug...(o_o)')
    end
end
[Nerr,ed]=Passage_Body(W,data);
%% 输出参数
GasOut.W=adverse*W*data.Num;
GasOut.Tt=ed.Tt2; 
GasOut.Ps=ed.Ps2;
GasOut.Pt=ed.Pt2;
GasOut.Ts=ed.Ts2;
GasOut.Sf=ed.Sf2;
GasOut.Swirl=ed.Swirl2;%涡参数 Swirl=omega_air*r^2
GasOut.Ma=ed.Ma;
end