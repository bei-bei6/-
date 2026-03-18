%放气阀开启与闭合控制  
%压气机后放气
if (data.PT_Shaft>data.HPCDeflate.Speed)&&(WholeEngine1(i+1).Others.Xdot_PTShaft>0)%涡轮放气
    data.HPCvalve=1;
end
if (data.PT_Shaft<data.HPCDeflate.Speed)&&(WholeEngine1(i+1).Others.Xdot_PTShaft<0)%涡轮放气
    data.HPCvalve=0;
end
%动力涡轮前放气
if (data.PT_Shaft>data.HPTDeflate.OpenSpeed)&&(WholeEngine1(i+1).Others.Xdot_PTShaft>0)%涡轮放气
    data.HPTvalve=1;
end
if (data.PT_Shaft<data.HPTDeflate.CloseSpeed)&&(WholeEngine1(i+1).Others.Xdot_PTShaft<0)%涡轮放气
    data.HPTvalve=0;
end

%放气系统参数计算
if ((data.HPTvalve)||(GasPth1(i).DeflateDuct.ValveOpening>0.001))&&(data.Deflatemethod==2)
    %获得上一时刻燃机参数
    Ptin=GasPth1(i+1).GasOut_HPT.Pt;
    Ttin=GasPth1(i+1).GasOut_HPT.Tt;   
    Ptout=GasPth1(i+1).GasOut_PT.Pt;%放气系统出口总压（动力涡轮后）
    Ttout=GasPth1(i+1).GasOut_PT.Tt;%放气系统出口总压（动力涡轮后）    
    Wmain=GasPth1(i+1).GasOut_PT.W;
    FARIn=GasPth1(i+1).GasOut_HPT.FAR;  
    htin=GasPth1(i+1).GasOut_HPT.ht;
    
    try
        state=data.Area;
    catch
        data.Area=0.558210536059335;
        data.Ain=pi*0.05*0.05*1.1; %inlet和outlet面积
        data.Aout=pi*0.05*0.05*1.1; %inlet和outlet面积
        data.Cd_in=1;
        data.Cd_out=0.7;
        data.Volume=5*pi*0.05*0.05;%体积
    end
    %求解放气系统出口背压
    Area=data.Area;
    d=0;
    Pb_left=Ptout*0.5;
    Pb_right=Ptout;
    htin=tf_dp2h(Ttout,FARIn,d,Ptout);
    while 1
        Pb=0.5*(Pb_left+Pb_right);
        S = ptf_d2s(Ptout,Ttout,FARIn,d)+log(abs(Pb/Ptout));%入口熵=出口熵
        Ts = spf_d2t(S,Pb,FARIn,d);%出口静温
        hs = tf_dp2h(Ts,FARIn,d,Pb);%出口静焓
        [gammar,Rg]=tfd2gammarRg(Ts,FARIn,d);%此处需要使用燃气的物性参数
        rhos = Pb * divby(Rg* Ts);%密度
        V = sqrtT(2 * (htin - hs));%出口速度
        Wout = Area*rhos*V;

        if Wout<Wmain
            Pb_right=Pb;
        else
            Pb_left=Pb;
        end

        if abs(Wout-Wmain)<0.01
            break
        end

    end

    %求解该时刻排气系统参数
    GasIn.Pt=Ptin;
    GasIn.Tt=Ttin;
    data.Psout=Pb;
    
    data.valve_opening=GasPth1(i).DeflateDuct.ValveOpening;
    
    y0=[GasPth1(i).DeflateDuct.Tt,GasPth1(i).DeflateDuct.Pt];%管路内的初始温度和压力和开度
    
    data.GasIn=GasIn;
    tspan=0:data.deltat/100:data.deltat;%时间步长
    F=@(t,y) funwrapper2(@Pipe_Body,t,y,data);%t为时间，y为[温度,压力]

    [t,y] = ode23s(F,tspan,y0);

    y=real(y); 
    [~,ed]=Pipe_Body(t(end),y(end,:),data);

    GasOut.FAR=FARIn;
    GasOut.W=ed.Wout;%放气阀出口流量
    GasOut.Pt=GasIn.Pt;%
    GasOut.Tt=GasIn.Tt;%
    GasOut.ht=htin;%
    
    data.HPTDeflate_Win=ed.Win;%放气阀进口流量
    data.HPTDeflate_GasOut=GasOut;
    
    GasPth1(i+1).DeflateDuct.Pt=ed.Pt;%管路压力  在engine程序中也计算了这个值，这里就直接覆盖掉
    GasPth1(i+1).DeflateDuct.Tt=ed.Tt;%管路温度    
    GasPth1(i+1).DeflateDuct.W=ed.W;%管路流量
    GasPth1(i+1).DeflateDuct.ValveOpening=ed.ValveOpening;%放气阀开度
end
