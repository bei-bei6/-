 function [P,data]=loading(time,data)
P_d=data.Power_d;
method=data.loadingmethod;%负载类型
PT_Shaft=data.PT_Shaft;%动力轴转速
switch method
    case 1
        %突增突卸载负载
        P=interp1g(data.LoadingTable.time,data.LoadingTable.Loading,time)*1000000;
    case 2
        %定螺距螺旋桨负载
        P=data.Propeller_C*PT_Shaft^3;
    case 3
        %发电机负载
        %nominal
        try
            %Python
            a=data.Generator.Udemand;
            data.Generator.R=interp1g(data.Generator.time,data.Generator.Rout,time);
        catch
            %matlab
            data.Generator.Udemand=10000;%额定电压=单相电压的有效值,V
            data.BASE_f=50;%基值频率,Hz
            %stator
            data.Generator.Rs=0.0016;%定子内阻
            data.Generator.Llou=1.414e-05;
            data.Generator.Lmd=0.001075;
            data.Generator.Lmq=0.0007917;
            %field（注意field基值不一样）
            data.Generator.Rf=0.0004763;%励磁内阻
            data.Generator.Lloufd=0.0004701;
            %damper
            data.Generator.Rkd=0.1821;%阻尼D绕组内阻
            data.Generator.Lloukd=0.006717;
            data.Generator.Rkq=0.002909;%阻尼Q绕组内阻
            data.Generator.Lloukq=7.338e-05;
            %外接参数
            data.Generator.R=interp1g([0;1;1;100],[15;15;30;30],time);
            %控制器
            data.Generator.Kp=0.03;
            data.Generator.Ki=0.01; 
        end


        %%
        Generator=data.Generator; 
        X0=1;
        Lmd=Generator.Lmd;
        Lmq=Generator.Lmq;
        Lflou=Generator.Lloufd;
        LDlou=Generator.Lloukd;
        LQlou=Generator.Lloukq;
        Llou=Generator.Llou;

        Xad=Lmd;
        Xaq=Lmq;
        Xd=Lmd+Llou;
        Xq=Lmq+Llou;
        Xf=Lmd+Lflou;
        XD=Lmd+LDlou;
        XQ=Lmq+LQlou;    
        L=[Xd 0 0 Xad Xad 0
        0 Xq 0 0 0 Xaq
        0 0 X0 0 0 0
        Xad 0 0 Xf Xad 0
        Xad 0 0 Xad XD 0
        0 Xaq 0 0 0 XQ];
%%
        data.Generator.f=data.BASE_f/6000*PT_Shaft;
        data.Generator.w=2*pi*data.Generator.f;
        w=data.Generator.w;
        pi2=2.*pi/3;
        
        data.Gene_deltat=data.deltat;%
        if time==0
            %确定励磁系统初始电压值和初始电流
          %%
            %励磁系统初始电压
            fenzi=(Generator.Lmd+Generator.Llou+((Generator.R+Generator.Rf)/data.Generator.w)^2/(Generator.Lmq+Generator.Llou))*Generator.Rf;
            fenmu=Generator.Lmd*Generator.R*sqrt(1+((Generator.R+Generator.Rf)/(Generator.Lmq+Generator.Llou)/data.Generator.w)^2);
            data.Generator.VF=sqrt(2)*Generator.Udemand*fenzi/fenmu;%当输出电压为目标电压时对应的励磁系统电压标幺值
            
            iF0 =data.Generator.VF/Generator.Rf;%励磁绕组初始电流
            id0_stast=Generator.Lmd*iF0/((Generator.Lmd+Generator.Llou)+((Generator.Rs+Generator.R)/data.Generator.w)^2/(Generator.Lmq+Generator.Llou));
            iq0_stast=(Generator.Rs+Generator.R)/(Generator.Lmq+Generator.Llou)/data.Generator.w*id0_stast;
            i_start = [-id0_stast; -iq0_stast; 0; iF0; 0; 0;]; % Initial currents电压初值
            
            data.Gene_PI_in=data.Generator.VF;%控制器
            data.Gene_int_error=0;
            
            t0 = 0 ; 
            tfinal = data.deltat;%整机时间步长
            tend=data.Gene_deltat;%电机时间步长
            
            while 1
                tspan=t0:0.0005:tend; 
                if tend>tfinal
                    data.i_start=i_start;
                    break;
                end
                t0=tend;
                tend=t0+data.Gene_deltat;

                Generator_cal=@(tspan,i0) funwrapper2(@Gllshort_si,tspan,i0,data.Generator);%
                [t,i] = ode23s(Generator_cal, tspan, i_start); % use for MATLAB 5
                id=-i(1:(end-1),1); iq=-i(1:(end-1),2);i0=-i(1:(end-1),3);iF=i(1:(end-1),4); iD=i(1:(end-1),5); iQ=i(1:(end-1),6);
                i_start=[-id(end);-iq(end);-i0(end);iF(end);iD(end);iQ(end)];
                %current dq0 to current abc
                nn=length(id);
                for kk=1:nn
                    tt=t(kk);
                    thetaa=w*tt;
                    thetab=thetaa-pi2;
                    thetac=thetaa+pi2;
                    ia(kk)=cos(thetaa)*id(kk)-sin(thetaa)*iq(kk)+i0(kk);
                    ib(kk)=cos(thetab)*id(kk)-sin(thetab)*iq(kk)+i0(kk);
            %         ic(kk)=cos(thetac)*id(kk)-sin(thetac)*iq(kk)+i0(kk);
                end
                ueff_i=sqrt(0.5*id(end).^2+0.5*iq(end).^2)*data.Generator.R;%端电压有效值，与整机时间步同频
                [data.Generator.VF_real,data.Gene_int_error]=GenePID(data.Generator.Udemand,ueff_i,data);
                data.Generator.VF=data.Generator.VF_real;
                data.Generator.VF_old=data.Generator.VF;
                ieff_i=ueff_i./data.Generator.R;

                F=L*(i(end-1,:)');%磁通量
                F_d=F(1);
                F_q=F(2);

                T=-1.5*F_d*i(end-1,2)+1.5*F_q*i(end-1,1);
                P=T*data.Generator.w;
            end
            data.Generator.Uoutput=ueff_i; 
            data.Generator.Power_demand=P; 
            data.Generator.fall=data.Generator.f;
            data.Generator.VFall=data.Generator.VF;
            data.Generator.Rall=data.Generator.R;
        else  
            t0=time;
            tfinal =t0+data.deltat;%整机时间步长
            tend=t0+data.Gene_deltat;%电机时间步长
            i_start=data.i_start;
             while 1
                tspan=t0:0.0005:tend; 
                if tend>tfinal
                    data.i_start=i_start;
                    break;
                end
                t0=tend;
                tend=t0+data.Gene_deltat;

                Generator_cal=@(tspan,i0) funwrapper2(@Gllshort_si,tspan,i0,data.Generator);%
                [t,i] = ode23s(Generator_cal, tspan, i_start); % use for MATLAB 5
                id=-i(1:(end-1),1); iq=-i(1:(end-1),2);i0=-i(1:(end-1),3);iF=i(1:(end-1),4); iD=i(1:(end-1),5); iQ=i(1:(end-1),6);
                i_start=[-id(end);-iq(end);-i0(end);iF(end);iD(end);iQ(end)];
                %current dq0 to current abc
                nn=length(id);
                for kk=1:nn
                    tt=t(kk);
                    thetaa=w*tt;
                    thetab=thetaa-pi2;
                    thetac=thetaa+pi2;
                    ia(kk)=cos(thetaa)*id(kk)-sin(thetaa)*iq(kk)+i0(kk);
                    ib(kk)=cos(thetab)*id(kk)-sin(thetab)*iq(kk)+i0(kk);
                end
                ueff_i=sqrt(0.5*id(end).^2+0.5*iq(end).^2)*data.Generator.R;%端电压有效值，与整机时间步同频
                [data.Generator.VF_real,data.Gene_int_error]=GenePID(data.Generator.Udemand,ueff_i,data);
                data.Generator.VF=data.Generator.VF_real+(data.Generator.VF_old-data.Generator.VF_real)*exp(-data.Gene_deltat/1);
                data.Generator.VF_old=data.Generator.VF;               
                ieff_i=ueff_i./data.Generator.R;


                F=L*(i(end-1,:)');%磁通量
                F_d=F(1);
                F_q=F(2);

                T=-1.5*F_d*i(end-1,2)+1.5*F_q*i(end-1,1);
                P=T*data.Generator.w;
            end
            data.Generator.Uoutput=[data.Generator.Uoutput,ueff_i]; 
            data.Generator.Power_demand=P; 
            data.Generator.fall=[data.Generator.fall,data.Generator.f];
            data.Generator.VFall=[data.Generator.VFall,data.Generator.VF];
            data.Generator.Rall=[data.Generator.Rall,data.Generator.R];
        end
    case 4
% 自定义负载    
    loadingDIY();
    case 5
% 自定义负载    
        if time<1
            P=data.Load_Initial_Value;
        else
            P=data.Load_Final_Value; 
        end
%%        
end
P=-P;
data.Load=P;
 end