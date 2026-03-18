function W=branch_2_use(Pt,Tt,Pb,Data)



    data.BC.GasPrimary.Tt=1.1767e3;
    
    % 高压涡轮静叶冷却支路进口总压总温
    data.BC.Pt1=Pt; % Pa 1.618043522549951e+06
    data.BC.Tt1=Tt; % K 
    
    % 排气点参数
    data.BC.Pamb1=Pb; % 高压涡轮静叶前总压*0.9，Pa 1529248.446*0.9
    
    
    data.BC.HP_Shaft=Data.HP_Shaft; % 高压涡轮转速，rpm
    data.BC.LP_Shaft=Data.LP_Shaft; % 低压涡轮转速，rpm
    %压力初值
    x0=linspace(data.BC.Pt1,data.BC.Pamb1,4);
    x0=x0(2:end-1);
    %%
    sas=@branch_2;
    FUN=@(x) funwrapper(sas,x,data);
    opt.maxiter=5000;
    opt.tolfun=1e-6;
    opt.tolx=1e-12;
    icount=1;imax=50;
    bounds=[0 data.BC.Pt1
    0 data.BC.Pt1];
    
    [x, ithist]=broyden(FUN,x0,opt,bounds);%
    [NErr,SAS_Data]=branch_2(x,data);
    W=SAS_Data.Hole1O.W;


end