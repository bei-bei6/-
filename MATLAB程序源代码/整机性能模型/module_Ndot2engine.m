    bounds1=[2 100
    -1 3
    -5 3
    -6 3
    0 10                                            
    ];
    FUN_LIMIT=@(x1) funwrapper(aircraft_limit2,x1,data);
    [x_type, ithist]=broyden(FUN_LIMIT,x1,opt,bounds1);%x_type1在第一种临界值情况（最大升转速率）下得到的迭代初值
    if ithist.normf(end)>opt.tolfun || isnan(ithist.normf(end))
        error('%s\n','临界高速轴转速升转速率Debug')
    end
    [~,GasPth1(i+1),WholeEngine1(i+1)]=engine_DS_NoSAS_LIMITall2(x_type,data);%这里保存的值是最终值
    %去掉pid的积分环节
    data.int_error_in=data.interror_in_old;
    data.int_error_out=data.interror_out_old;