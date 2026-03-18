 %给定油气比，求解燃机性能
data.type=5;
bounds=[2 100
-1 3
-5 3
-6 4
]; 
x0=x2(1:4);
FUN=@(x) funwrapper(aircraft,x,data);
[x, ithist]=broyden(FUN,x0,opt,bounds);%
if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
    fprintf('%s\n','Debug')
    error('%s\n','计算不收敛');
end
[~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS1(x,data);%这里保存的值是最终值
data.Wf=WholeEngine1(i+1).B_Data.Wf;
x2=[x;data.Wf];  