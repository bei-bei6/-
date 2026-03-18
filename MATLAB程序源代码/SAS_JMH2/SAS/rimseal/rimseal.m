function [GasOut,ed]=rimseal(GasIn,Pb,data)
%% 公式引用自文献A study of turbomachinery compressible gas labyrinth seal rotordynamic coefficients
data.GasIn=GasIn;
data.Pb=Pb; %Psout
%% 逆流？
if data.Pb>data.GasIn.Pt
    fprintf('%s\n','轮缘封严逆流')
    data.adverse=-1;
    [data.GasIn,data.Pb]=swap(data.GasIn,data.Pb);
else
    data.adverse=1;
end

%% 计算临界压比
data.sign=1; %壅塞（临界状态）
x0 = data.GasIn.Pt/2; % 预估出口总压
bounds=[0 data.GasIn.Pt];
opt.maxiter=500;
opt.tolfun=1e-6;
opt.tolx=1e-12;
FUN=@(x) funwrapper(@rimseal_body,x,data);
[Pt2cri, ithist]=broyden(FUN,x0,opt,bounds);% 调用牛顿法迭代求解
if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
    fprintf('轮缘封严迭代未收敛\n')
    return
end
[~,edcri]=rimseal_body(Pt2cri,data);
Pbcri=edcri.Ps2;
%%
if Pbcri>=data.Pb
    fprintf('轮缘封严出口壅塞\n')
    GasOut.W= data.adverse*edcri.W;
    if data.adverse==-1
        GasOut.Pt=data.GasIn.Pt;
    elseif data.adverse==1
        GasOut.Pt=edcri.Pt2;
    end
    GasOut.Tt=edcri.Tt2;
    GasOut.Swirl=edcri.Swirl2;
    ed=edcri;
else
    data.sign=0; %亚临界状态
    x0 = 0.5; % 预估出口马赫数
    bounds=[0 1];
    opt.maxiter=500;
    opt.tolfun=1e-6;
    opt.tolx=1e-12;
    FUN=@(x) funwrapper(@rimseal_body,x,data);
    [Ma2, ithist]=broyden(FUN,x0,opt,bounds);% 调用牛顿法迭代求解
    if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
        fprintf('轮缘封严迭代未收敛\n')
        return
    end
    [~,ed]=rimseal_body(Ma2,data);
    GasOut.W= data.adverse*ed.W;
    if data.adverse==-1
        GasOut.Pt=data.GasIn.Pt;
    elseif data.adverse==1
        GasOut.Pt=ed.Pt2;
    end
    GasOut.Tt=ed.Tt2;
    GasOut.Swirl=ed.Swirl2;
end
end
