%给定燃油流量，求解燃机性能
% function [GasPth1,WholeEngine1,x2]=module_wf2engine(x2,data)
    data.type=1;
    bounds=[2 100
    -1 3
    -5 3
    -6 4
    ]; 
    x0=x2(1:4);
    if data.HGC.SAS,x0(5,1)=1960882.85266362;bounds=[bounds;1e5,5e6];end
    FUN=@(x) funwrapper(aircraft,x,data);
    [x, ithist]=broyden(FUN,x0,opt,bounds);%
    if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
        fprintf('%s\n','Debug')
        error('%s\n','计算不收敛');
    end
    [~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS1(x,data);%这里保存的值是最终值
    x2=[x;data.Wf];
% end