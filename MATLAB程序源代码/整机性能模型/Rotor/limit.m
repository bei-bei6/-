%% 更新限制值
theta = data.T0 / data.Cons.C_TSTD;
HP_Shaft_cor=data.HP_Shaft*divby(sqrtT(theta));
%求解限制值
if data.HP_Shaft<11900
    data.maxXdot_HPShaft=60;
else
    data.maxXdot_HPShaft=60;
end
if HP_Shaft_cor<11600
    data.minXdot_HPShaft=-50;
else
    data.minXdot_HPShaft=-50;
end


data.minXdot_HPShaft=interp2g(13600:-20:8500,7000:-1000:3000,HPS_Ndot,HP_Shaft_cor,data.PT_Shaft);


% data.maxXdot_HPShaft=interp1g(LIMIT.maxXdot_HPShaft_X,LIMIT.maxXdot_HPShaft_Y,HP_Shaft_cor);%最大升转速率限制
% data.minXdot_HPShaft=interp1g(LIMIT.minXdot_HPShaft_X,LIMIT.minXdot_HPShaft_Y,HP_Shaft_cor);%最大降转速率限制
%求解限制值
data.maxFAR=interp1g(LIMIT.maxFAR_X,LIMIT.maxFAR_Y,HP_Shaft_cor);%最大升转速率限制
data.minFAR=interp1g(LIMIT.minFAR_X,LIMIT.minFAR_Y,HP_Shaft_cor);%最大降转速率限制




%% 判断超调
%保留一定裕量1.001,否则程序可能会受到迭代误差影响陷入死循环
%最大加速率
if (Xdot_HPShaft>data.maxXdot_HPShaft*1.001)
    
    x1=[x0;WholeEngine1(end-1).B_Data.Wf];
    bounds1=[2 60
    -1 3
    -1 3
    -5 3
    0 10
    ];

    limit_signal=1;
    data.limit_method=1;
    
    FUN_LIMIT=@(x1) funwrapper(aircraft_limit,x1,data);
    [x2, ithist]=broyden(FUN_LIMIT,x1,opt,bounds1);%
    if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
        fprintf('%s\n','临界高速轴转速加速度Debug')
    end

    [~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS_NoSAS_LIMIT(x2,data);
end
%最小加速率
if (Xdot_HPShaft<data.minXdot_HPShaft*1.001)

    if limit_signal==1
        x1=x2;%超过了别的限制值，使用之前limit计算得到的参数
    else
        x1=[x0;WholeEngine1(end-1).B_Data.Wf];%当前是超过的第一个限制值，使用上一时刻的参数
    end
    
    bounds1=[2 60
        -1 3
        -1 3
        -5 3
        0 10
        ];
    limit_signal=1;
    data.limit_method=2;
    
    FUN_LIMIT=@(x1) funwrapper(aircraft_limit,x1,data);
    [x2, ithist]=broyden(FUN_LIMIT,x1,opt,bounds1);%
    if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
        fprintf('%s\n','临界高速轴转速加速度Debug')
    end
    
    [~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS_NoSAS_LIMIT(x2,data);
end


%%
%最大wf/p3
% if (data.Wf*divby(GasPth1(i+1).GasOut_HPC.Pt)>data.maxFAR*1.001)
%     limit_signal=1;
%     data.limit_method=3;
%     %重置上一时间步参数
%     i=i-1;
%     %迭代初值
%     x1=[x;data.Wf];
%     bounds1=[2 60
%     -1 3
%     -1 3
%     -5 3
%     0 10
%     ];
%     FUN_LIMIT=@(x1) funwrapper(aircraft_limit,x1,data);
%     [x2, ithist]=broyden(FUN_LIMIT,x1,opt,bounds1);%
%     if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
%         fprintf('%s\n','临界高速轴转速加速度Debug')
%     end
% %     data.condition_HP_Shaft=0;
%     data.Wf=x2(5);
% end
%最小wf/p3
% if (data.Wf*divby(GasPth1(i+1).GasOut_HPC.Pt)<data.minFAR*0.999)
%     limit_signal=1;
%     data.limit_method=4;
%     %重置上一时间步参数
%     i=i-1;
%     %迭代初值
%     x1=[x;data.Wf];
%     bounds1=[2 60
%     -1 3
%     -1 3
%     -5 3
%     0 10
%     ];
%     FUN_LIMIT=@(x1) funwrapper(aircraft_limit,x1,data);
%     [x2, ithist]=broyden(FUN_LIMIT,x1,opt,bounds1);%
%     if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
%         fprintf('%s\n','临界高速轴转速加速度Debug')
%     end
% %     data.condition_HP_Shaft=0;
%     data.Wf=x2(5);
% end



