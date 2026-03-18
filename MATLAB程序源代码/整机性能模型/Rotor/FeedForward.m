%前馈控制
feedforward=data.feedforward;%是否开启的前馈控制

loadnow=abs(data.Load);
%计算负载发生的变化量，如果第一次发生变化，那么比较当前负载和0时刻负载大小，如果第二次及之后发生变化，使用上次计算前馈时候的负载进行比较
try 
    Loadchange=abs((loadnow-loadold)*divby(loadold));
catch
    loadold=WholeEngine1(1).Others.Load;
    Loadchange=abs((loadnow-loadold)*divby(loadold));
end
if (feedforward)&&(Loadchange>0.2)%开启了前馈并且负载发生了变化
    %将动力轴转速变为设定值
    PT_Shaft_real=data.PT_Shaft;
%     data.PT_Shaft=WholeEngine1(1).PT_Shaft;
    data.PT_Shaft=y_demand;
    loadold=loadnow;
    for j=1:length(x0_sheet)
        x_f(j,1)=interp1g(-data.Power_d.*[1:-0.2:0.2],x0_sheet(j,:),-loadnow);
    end
    aircraft_FF=@engine_SS;
    FUN=@(x) funwrapper(aircraft_FF,x,data);
    opt.maxiter=1000;%最大迭代次数
    opt.tolfun=1e-6;%收敛容差
    opt.tolx=1e-12;%最小变化量
    bounds=[10 60
        -0.3 1.1
        0 0.3
        -0.3 1.1
        -0.3 1.1
        0 20000
        ];
    if data.HGC.SAS,bounds=[bounds;1e5,5e6];else x_f(end)=[];end
    [x_f, ithist]=broyden(FUN,x_f,opt,bounds);%,bounds
    [~,GasPth,WholeEngine]=engine_SS(x_f,data);
    data.PI_in=x_f(3)*GasPth.GasOut_HPC.W*3600/0.81/9;
    data.PI_out=x_f(6);
    data.int_error_in=0;
    data.int_error_out=0;
    Ng_S=x_f(6);
    %恢复动力轴转速
    data.PT_Shaft=PT_Shaft_real;
end