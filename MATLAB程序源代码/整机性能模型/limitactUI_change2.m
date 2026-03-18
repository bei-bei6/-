%% 更新限制值
theta = data.T0 / data.Cons.C_TSTD;
HP_Shaft_cor=data.HP_Shaft*divby(sqrtT(theta));
%% 检测负载功率变化
LoadChangeRate=(abs(data.Load)-WholeEngine1(i).Others.Load)*divby(data.deltat);
%负载变化检测
%% 控制模式 
if data.OpenControl.Switch==1
    % 开环油气比计算
    % 负载变化率计算
%     LoadChangeRate=(abs(data.Load)-WholeEngine1(i).Others.Load)*divby(data.deltat);
    %负载变化检测
    if LoadChangeRate>data.OpenControl.MaxLoadChangeRate
        OpenControlMethod=2;
        FeedForward;
    elseif LoadChangeRate<data.OpenControl.MinLoadChangeRate
        OpenControlMethod=3;
        FeedForward;
    end
    %恢复
    if abs(data.HP_Shaft-Ng_S)<data.returnPID_open
        OpenControlMethod=4;
        FeedForward;
    end
else
    if i==1
        OpenControlMethod=1;
    end
    if LoadChangeRate>100
        CalMehthod=2;
        FeedForward; 
    elseif LoadChangeRate<-100
        CalMehthod=3;
        FeedForward; 
    end
    %恢复
    if abs(data.HP_Shaft-Ng_S)<data.returnPID
        OpenControlMethod=4;
        FeedForward
    end
end
%%
%求解限制值
data.maxXdot_HPShaft=interp1g(LIMIT.maxXdot_HPShaft_X,LIMIT.maxXdot_HPShaft_Y,HP_Shaft_cor);
data.minXdot_HPShaft=interp1g(LIMIT.minXdot_HPShaft_X,-abs(LIMIT.minXdot_HPShaft_Y),HP_Shaft_cor);
data.maxWfP3=interp1g(LIMIT.maxFAR_X,LIMIT.maxFAR_Y,HP_Shaft_cor);
data.minWfP3=interp1g(LIMIT.minFAR_X,LIMIT.minFAR_Y,HP_Shaft_cor);

maxXdot_HPShaft_all=[maxXdot_HPShaft_all,data.maxXdot_HPShaft];
minXdot_HPShaft_all=[minXdot_HPShaft_all,data.minXdot_HPShaft];
%% 求解限制值状态下的油气比和燃机参数
%最大升转速率
OpenControlMethod=5;
switch OpenControlMethod
    case 1 %正常计算
        %%
        %PID计算
        [data.Wf,data.int_error_in,data.int_error_out,HPShaft_need(i+1),data.interror_in_old,data.interror_out_old]=doublePID(y_demand,data.HP_Shaft,data.PT_Shaft,data);  
        if data.Wf<data.Fuel_MinM
            data.int_error_in=data.interror_in_old;
            data.int_error_out=data.interror_out_old;            
            data.Wf=data.Fuel_MinM;
        end
        
        if data.LimitOpen
            switch CalMehthod
                case 1
                    %如果为1，则首先计算PID后的燃机性能，然后进行校核；如果为2，首先进行升转速率计算，然后进行降转速率计算；如果为3，反之。
                    %使用PID计算的燃油流量计算
                    data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
                    module_wf2engine;
                    %校核
                    WfP3=WholeEngine1(i+1).B_Data.Wf/GasPth1(i+1).GasOut_HPC.Pt;
                    if (WholeEngine1(i+1).Others.Xdot_HPShaft>data.maxXdot_HPShaft)||(WfP3>data.maxWfP3)
                        CalMehthod=2;
                        data.type=1;%定义求解的限制值类型
                        if isempty(x_type1)
                            x1=x2;
                        else
                            x1=x_type1;
                        end
                        module_Ndot2engine;
                        x_type1=x_type;
                        x2=x_type;
                    elseif (WholeEngine1(i+1).Others.Xdot_HPShaft<data.minXdot_HPShaft)||(WfP3<data.minWfP3)
                        CalMehthod=3;
                        data.type=2;%定义求解的限制值类型
                        if isempty(x_type2)
                            x1=x2;
                        else
                            x1=x_type2;
                        end
                        module_Ndot2engine;
                        x_type2=x_type;
                        x2=x_type;
                    end
                case 2
                    %计算最大燃油流量
                    try
                        data.type=1;%定义求解的限制值类型
                        if isempty(x_type1)
                            x1=x2;
                        else
                            x1=x_type1;
                        end
                        module_Ndot2engine;
                        x_type1=x_type;
                        fuel_max=x_type1(5);
                    catch
                        %如果最大升转速率求解有问题，那么使用最大油气比求解试试
                        fprintf('%s\n',['升工况限制值计算不收敛，不收敛时刻为第',num2str(data.CT,'%f  '),'秒，建议修改限制值大小或减少时间步长']);
                        fuel_max=x2(5);
                        x_type1=x2;
                    end 

                    if data.Wf>fuel_max%PID算出的燃油流量过大，采用限制值作为真实燃油流量
                        if data.fuel_delay==0
                            x2=x_type1;
                        else
                            data.Wf=fuel_max+(data.Wf_old-fuel_max)*exp(-data.deltat*divby(data.fuel_delay));
                            module_wf2engine;
                        end
                        FeedForward; 
                    else
                        %负载up之后，却没有到up的限制值；计算降转速率情况
                         try
                            data.type=2;%定义求解的限制值类型
                            if isempty(x_type2)
                                x1=x2;
                            else
                                x1=x_type2;
                            end
                            module_Ndot2engine
                            fuel_min=x_type(5);
                         catch
                            fprintf('%s\n',['降工况限制值计算不收敛，不收敛时刻为第',num2str(data.CT,'%f  '),'秒，建议修改限制值大小或减少时间步长']);
                            fuel_min=x2(5);
                            x_type2=x2;
                        end
                        if data.Wf<fuel_min%PID算出的燃油流量过小，采用限制值
                            if data.fuel_delay==0
                                x2=x_type2;
                            else
                                data.Wf=fuel_min+(data.Wf_old-fuel_min)*exp(-data.deltat*divby(data.fuel_delay));
                                x0=x_type2(1:4);
                                module_wf2engine;
                            end
                            FeedForward; 
                        else
                            %情况恢复，使用PID 计算
                            module_wf2engine;
                            CalMehthod=1;
                        end
                    end
                case 3
                    %计算最小燃油流量
                     try
                        data.type=2;%定义求解的限制值类型
                        if isempty(x_type2)
                            x1=x2;
                        else
                            x1=x_type2;
                        end
                        module_Ndot2engine;
                        x_type2=x_type;
                        fuel_min=x_type(5);
                    catch
                        %如果最大升转速率求解有问题，那么使用最大油气比求解试试
                        fuel_min=x2(5);
                        x_type2=x2;
                    end 

                    if data.Wf<fuel_min%
                        if data.fuel_delay==0
                            x2=x_type2;
                        else
                            data.Wf=fuel_min+(data.Wf_old-fuel_min)*exp(-data.deltat*divby(data.fuel_delay));
                            module_wf2engine;
                        end
                        FeedForward; 
                    else
                        %负载突降之后，却没有到突降的限制值；计算最大油气比的情况
                          try
                            data.type=1;%定义求解的限制值类型
                            if isempty(x_type1)
                                x1=x2;
                            else
                                x1=x_type1;
                            end
                            
                            module_Ndot2engine
                            fuel_max=x_type(5);
                        catch
                            fuel_max=x2(5);
                            x_type1=x2;
                        end
                        if data.Wf>fuel_max%PID算出的燃油流量过大，采用限制值
                            if data.fuel_delay==0
                                x2=x_type1;
                            else
                                data.Wf=fuel_max+(data.Wf_old-fuel_max)*exp(-data.deltat*divby(data.fuel_delay));
                                module_wf2engine;
                            end
                            %去掉pid的积分环节
                            data.int_error_in=data.interror_in_old;
                            data.int_error_out=data.interror_out_old;

                            FeedForward; 
                        else
                            %情况恢复，使用PID 计算
                            module_wf2engine;
                            CalMehthod=1;
                        end
                    end  
            end
        else
            data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
            module_wf2engine;
        end
        %%
    case 2
        %开环油气比控制：升工况
        data.fuel_delay=data.fuel_delay_WfP3;
        data.WfP3=interp1g(data.OpenControl.MaxFarTable_X,data.OpenControl.MaxFarTable_Y,HP_Shaft_cor);
        module_wfP32engine;
        if data.fuel_delay~=0
            data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
            module_wf2engine;
        end

        %补充数据
        x_type1=[];
        x_type2=[];
        HPShaft_need(i+1)=0;
    case 3   
        %开环油气比控制：降工况
        data.fuel_delay=data.fuel_delay_WfP3;
        data.WfP3=interp1g(data.OpenControl.MinFarTable_X,data.OpenControl.MinFarTable_Y,HP_Shaft_cor);
        module_wfP32engine;
        if data.fuel_delay~=0
            data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
            module_wf2engine;
        end
        %补充数据
        x_type1=[];
        x_type2=[];
        HPShaft_need(i+1)=0;
     case 4  
        %纯PID控制
        data.Kp_out=data.Kp_out_PID;
        data.Ki_out=data.Ki_out_PID;
        data.Kp_in=data.Kp_in_PID;
        data.Ki_in=data.Ki_in_PID;
        data.fuel_delay=data.fuel_delay_PID;
        [data.Wf,data.int_error_in,data.int_error_out,HPShaft_need(i+1),data.interror_in_old,data.interror_out_old]=doublePID(y_demand,data.HP_Shaft,data.PT_Shaft,data);
        if data.Wf<data.Fuel_MinM
            data.int_error_in=data.interror_in_old;
            data.int_error_out=data.interror_out_old;            
            data.Wf=data.Fuel_MinM;
        end
        data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
        module_wf2engine;
      case 5  
        %pid控制+最大最小燃油流量限制
%         data.Kp_out=data.Kp_out_PID;
%         data.Ki_out=data.Ki_out_PID;
%         data.Kp_in=data.Kp_in_PID;
%         data.Ki_in=data.Ki_in_PID;
        data.fuel_delay=data.fuel_delay_PID;
        [data.Wf,data.int_error_in,data.int_error_out,HPShaft_need(i+1),data.interror_in_old,data.interror_out_old]=doublePID(y_demand,data.HP_Shaft,data.PT_Shaft,data);

        Ncor = [8683.88606776347, 9058.77785196143, 9394.34160276425, 9706.02965973234, 9932.07193249866, ...
            10115.0048150097, 10289.0376677199, 10458.9924917373, 10588.3449357983, 10704.5304152651, ...
            10823.7041717003, 10946.1460881820, 11068.9876258284, 11191.6748564835, 11294.2068058404, ...
            11395.9359416565, 11497.8950478763, 11598.5219697104, 11699.5602406338, 11800.6415497592, ...
            11899.8993566272, 12000.7932577582, 12103.0137315930, 12206.4759354539, 12312.4722099468, ...
            12418.9331192754, 12526.6103522208, 12640.3156620590, 12763.5887724886, 12886.8720618447, ...
            13010.7999066702, 13134.9200673604, 13258.9180688689, 13382.4514103067, 13505.8487548013, ...
            13630.0308905638, 13753.3807728351, 13876.6891768619, 14000.0529937241, 14125.7524020423, ...
            14249.8573271417, 14373.8053022202, 14497.7486236621, 14621.0551056017, 14742.5035232464, ...
            14863.5076446392, 14984.5331720971];
        
        WF_up_limit = [0.365557300696184, 0.418425589307696, 0.463209882184089, 0.502309646370824, 0.538113687016442, ...
            0.570949485450623, 0.601208937718531, 0.631819980008576, 0.663768189869060, 0.694992314347955, ...
            0.727012946129321, 0.758870064272139, 0.789844985533820, 0.820969261986016, 0.854500353850724, ...
            0.887778146867397, 0.920982925936993, 0.954317419485480, 0.987341036515977, 1.02016856687198, ...
            1.05358796501534, 1.08755846408790, 1.12133584099658, 1.15532109850002, 1.18955149036432, ...
            1.22363281049320, 1.25745665425411, 1.29142212959422, 1.32575018402444, 1.36004752991627, ...
            1.39421869637938, 1.42864203897366, 1.46310566966369, 1.49870305892335, 1.53510228794380, ...
            1.57154343570589, 1.60805649071722, 1.64449774756109, 1.68086314768788, 1.72520896769348, ...
            1.77021230698673, 1.81548783834415, 1.86152982292398, 1.90775457987571, 1.95460707341904, ...
            2.00180037825299, 2.04956803536512].*1.5;
        WF_down_limit = [0.365557300696184, 0.418425589307696, 0.463209882184089, 0.502309646370824, 0.538113687016442, ...
            0.570949485450623, 0.601208937718531, 0.631819980008576, 0.663768189869060, 0.694992314347955, ...
            0.727012946129321, 0.758870064272139, 0.789844985533820, 0.820969261986016, 0.854500353850724, ...
            0.887778146867397, 0.920982925936993, 0.954317419485480, 0.987341036515977, 1.02016856687198, ...
            1.05358796501534, 1.08755846408790, 1.12133584099658, 1.15532109850002, 1.18955149036432, ...
            1.22363281049320, 1.25745665425411, 1.29142212959422, 1.32575018402444, 1.36004752991627, ...
            1.39421869637938, 1.42864203897366, 1.46310566966369, 1.49870305892335, 1.53510228794380, ...
            1.57154343570589, 1.60805649071722, 1.64449774756109, 1.68086314768788, 1.72520896769348, ...
            1.77021230698673, 1.81548783834415, 1.86152982292398, 1.90775457987571, 1.95460707341904, ...
            2.00180037825299, 2.04956803536512].*0.5;
        WF_up = interp1g(Ncor, WF_up_limit,HP_Shaft_cor);
        WF_down = interp1g(Ncor, WF_down_limit,HP_Shaft_cor); 

        if data.Wf>WF_up || data.Wf<WF_down
            doct=1;
        end

        data.Wf = max(min(data.Wf, WF_up), WF_down);
        data.Wf=data.Wf+(data.Wf_old-data.Wf)*exp(-data.deltat*divby(data.fuel_delay));
        module_wf2engine;
end
WholeEngine1(i+1).Others.HPShaft_need=HPShaft_need(i+1);
WholeEngine1(i+1).Others.maxXdot_HPShaft=data.maxXdot_HPShaft;
WholeEngine1(i+1).Others.minXdot_HPShaft=data.minXdot_HPShaft;   
data.Wf_old=WholeEngine1(i+1).B_Data.Wf;
%放气阀开闭控制
valve();
