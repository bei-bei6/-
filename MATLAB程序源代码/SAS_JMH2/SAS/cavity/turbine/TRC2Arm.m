function GasOut=TRC2Arm(GasIn,W,data)%W=1
%%
if W==0
    GasOut=GasIn;
    return
end

%%
data.GasIn=GasIn;
data.W=W;

cp=data.Cons.cp;
mu=data.Cons.mu;
k=data.Cons.k;
omega_disk=data.RES/60*2*pi;%RES为转速，单位rpm，转化为rad/s
if data.direction==1
    for i=1:data.Geo.N
        R1=(data.Geo.face{i,2}(2)+data.Geo.face{i,3}(2))/2;%控制体低位半径R1=0.05
        R2=(data.Geo.face{i,4}(2)+data.Geo.face{i,1}(2))/2;%控制体高位半径R2=0.075
        p12=distance_p(data.Geo.face{i,1},data.Geo.face{i,2});
        p23=distance_p(data.Geo.face{i,2},data.Geo.face{i,3});
        p34=distance_p(data.Geo.face{i,3},data.Geo.face{i,4});
        p41=distance_p(data.Geo.face{i,4},data.Geo.face{i,1});
        Rm=(R1+R2)/2;%控制体中心半径

        A1=2*pi*R1*p23*sin(data.Geo.theta(i,2));%进口面积
        A2=2*pi*R2*p41*sin(data.Geo.theta(i,4));%出口面积
        if i==1
            Pt1=data.GasIn.Pt;
            Tt1=data.GasIn.Tt;
            Swirl1=data.GasIn.Swirl;%0
        else
            Pt1=Pt2;%
            Tt1=Tt2;%
            Swirl1=Swirl2;%
        end
        [~,Ts1,~,rho1,Vr1,~]=WcalcStat(Pt1,Tt1,W,A1,data);%【Ts1为入口静温？】，Vr1为绝对速度
        omega1=Swirl1/R1^2;%0【气流的旋转角速度】
        dh=(p23+p41);%【特征尺寸】0.1

        Rew=rho1*abs(omega1-max(omega_disk))*Rm^2/mu;%旋转雷诺数（取平均半径位置）
        Rer=rho1*Vr1*dh/mu;%雷诺数
        roughness=1/2*(data.boundary.roughness(i,1)+data.boundary.roughness(i,3));%0
        if Rer<4000%【应当是2000？？？】
            f_Darch=64/Rew;%达西摩擦因子，公式来源？
        elseif Rer>=4000
            f_Darch=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;%达西摩擦因子，%【这个公式所用的Re为旋转雷诺数？】
        else%【线性插值？】
            fl=64/Rer;
            ft=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;
            por=(Rew-2000)/2000;
            f_Darch=por*ft+(1-por)*fl;
        end
        K=f_Darch*((p12+p34)/2)/dh;% Loss coefficient（与流动参数有关的摩擦损失系数K_2）： (p12+p34)/2表示控制体在流动方向上的有效长度
        Pt2=Pt1-K*W^2/(2*rho1*A1);%【压力方程？涡旋压升考虑了吗？】

        %% 传热过程
        %温升计算
        A=abs(pi*R2^2-pi*R1^2);

        Tf_p=find(data.boundary.htt(i,:)==1);% position 定壁温边界位置，返回索引1
        hT_p=find(data.boundary.htt(i,:)==0);% position 定热流边界位置，返回索引3
        n_Tf_p=length(Tf_p);% 1 定壁温边界数量
        n_hT_p=length(hT_p);% 1 定热流边界数量

        Tot_Qcell=0;

        for ii=1:n_Tf_p %循环计算每一个定壁温边界面的换热量
            diff_T=data.boundary.Tf(i,Tf_p(ii))-Ts1;%温差=壁面温度-入口静温？ diff_T=Td-Ts1;
            if n_Tf_p==1 && Tf_p(ii)==3
                ii=ii+1;
            end
            Pr=cp*mu/k;%普朗特数

            if Rew<4000%【和大论文的公式以及适用范围对不上】
                Nu=0.664*Rew^0.5*Pr^0.333;
            elseif Rew>=4000
                Nu=0.023*Rew^0.8*Pr^0.4;
            end

            HTCi=Nu*k/Rm;%换热系数h，控制体中心半径 Rm=(R1+R2)/2

            Tf_Q=HTCi*A*diff_T;
            Tot_Qcell=Tot_Qcell+Tf_Q;
        end

        for ii=1:n_hT_p %循环计算每一个定热流边界面的换热量
            hT_Q=data.boundary.tH(i,hT_p(ii));
            Tot_Qcell=Tot_Qcell+hT_Q*A;
            HTCi=0;
            Nu=0;
        end

        Tt2=Tt1+Tot_Qcell/(W*cp);
        Ct_p=find(~isnan(data.boundary.htt(i,:)));%寻找非NaN元素的地址：1 3
        %%
        %角动量守恒方程
        CoreSR=omega1/max(omega_disk);%旋流比=气流旋转角速度/转盘的旋转角速度
        if CoreSR<1
            Cf(1:data.Geo.N,:)=[0.063/Rew^0.2/CoreSR^-1.87 NaN 0.042/Rew^0.2/(1-CoreSR)^-1.35 NaN].*ones(data.Geo.N,4); % 转矩系数[cf_stator NaN cf_rotor NaN]
        else%旋流比≥1
            Cf(1:data.Geo.N,:)=[0.073/Rew^0.2 NaN 0.073/Rew^0.2 NaN].*ones(data.Geo.N,4); % 转矩系数【这个公式哪来的？？】
        end
        rotor=find(data.boundary.type(i,:)==1);%3
        stator=find(data.boundary.type(i,:)==0);%1
        for ii=1:length(Ct_p)%length(Ct_p)为2
            if length(rotor)==2 %若两壁面均为旋转面
                ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;%作用在转盘表面的力矩【此处的(omega_disk(ii)-omega1)与论文omega定义不同】
            elseif length(stator)==2 %若两壁面均为静止面
                ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
            elseif Ct_p(ii)==rotor
                ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;
            elseif Ct_p(ii)==stator
                ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
            end
        end
        Tot_ti=sum(ti);%总力矩M_disk
        Swirl2=(W*Swirl1+Tot_ti)/W; %（气流的）Swirl2=Omega(air)_out*r_out^2
    end
elseif data.direction==-1
    for i=data.Geo.N:-1:1
        R1=(data.Geo.face{i,2}(2)+data.Geo.face{i,3}(2))/2;%控制体低位半径R1=0.05
        R2=(data.Geo.face{i,4}(2)+data.Geo.face{i,1}(2))/2;%控制体高位半径R2=0.075
        p12=distance_p(data.Geo.face{i,1},data.Geo.face{i,2});
        p23=distance_p(data.Geo.face{i,2},data.Geo.face{i,3});
        p34=distance_p(data.Geo.face{i,3},data.Geo.face{i,4});
        p41=distance_p(data.Geo.face{i,4},data.Geo.face{i,1});
        Rm=(R1+R2)/2;%控制体中心半径

        A1=2*pi*R1*p23*sin(data.Geo.theta(i,2));%出口面积
        A2=2*pi*R2*p41*sin(data.Geo.theta(i,4));%进口面积
        if i==data.Geo.N
            Pt1=data.GasIn.Pt;
            Tt1=data.GasIn.Tt;
            Swirl1=data.GasIn.Swirl;%0
        else
            Pt1=Pt2;%
            Tt1=Tt2;%
            Swirl1=Swirl2;%
        end
        [~,Ts1,~,rho1,Vr1,~]=WcalcStat(Pt1,Tt1,W,A2,data);%Vr1为绝对速度
        omega1=Swirl1/R2^2;%0【气流的旋转角速度】
        dh=(p23+p41);%特征尺寸

        Rew=rho1*abs(omega1-max(omega_disk))*Rm^2/mu;%旋转雷诺数（取平均半径位置）
        Rer=rho1*Vr1*dh/mu;%雷诺数
        roughness=1/2*(data.boundary.roughness(i,1)+data.boundary.roughness(i,3));%0
        if Rer<4000%【应当是2000？？？】
            f_Darch=64/Rew;%达西摩擦因子，公式来源？
        elseif Rer>=4000
            f_Darch=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;%达西摩擦因子，%【这个公式所用的Re为旋转雷诺数？】
        else % 线性插值
            fl=64/Rer;
            ft=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;
            por=(Rew-2000)/2000;
            f_Darch=por*ft+(1-por)*fl;
        end
        K=f_Darch*((p12+p34)/2)/dh;% Loss coefficient（与流动参数有关的摩擦损失系数K_2）： (p12+p34)/2表示控制体在流动方向上的有效长度
        Pt2=Pt1-K*W^2/(2*rho1*A2);%【压力方程？涡旋压升考虑了吗？】

        %% 传热过程
        %温升计算
        A=abs(pi*R2^2-pi*R1^2);

        Tf_p=find(data.boundary.htt(i,:)==1);% position 定壁温边界位置，返回索引1
        hT_p=find(data.boundary.htt(i,:)==0);% position 定热流边界位置，返回索引3
        n_Tf_p=length(Tf_p);% 1 定壁温边界数量
        n_hT_p=length(hT_p);% 1 定热流边界数量

        Tot_Qcell=0;

        for ii=1:n_Tf_p %循环计算每一个定壁温边界面的换热量
            diff_T=data.boundary.Tf(i,Tf_p(ii))-Ts1;%温差=壁面温度-入口静温？ diff_T=Td-Ts1;
            if n_Tf_p==1 && Tf_p(ii)==3
                ii=ii+1;
            end
            Pr=cp*mu/k;%普朗特数

            if Rew<4000%【和大论文的公式以及适用范围对不上】
                Nu=0.664*Rew^0.5*Pr^0.333;
            elseif Rew>=4000
                Nu=0.023*Rew^0.8*Pr^0.4;
            end

            HTCi=Nu*k/Rm;%换热系数h，控制体中心半径 Rm=(R1+R2)/2

            Tf_Q=HTCi*A*diff_T;
            Tot_Qcell=Tot_Qcell+Tf_Q;
        end

        for ii=1:n_hT_p %循环计算每一个定热流边界面的换热量
            hT_Q=data.boundary.tH(i,hT_p(ii));
            Tot_Qcell=Tot_Qcell+hT_Q*A;
            HTCi=0;
            Nu=0;
        end

        Tt2=Tt1+Tot_Qcell/(W*cp);
        Ct_p=find(~isnan(data.boundary.htt(i,:)));%寻找非NaN元素的地址：1 3
        %%
        %角动量守恒方程
        CoreSR=omega1/max(omega_disk);%旋流比=气流旋转角速度/转盘的旋转角速度
        rotor=find(data.boundary.type(i,:)==1);%3
        stator=find(data.boundary.type(i,:)==0);%1
        Cf=ones(data.Geo.N,4)*nan;
        if CoreSR<1
            Cf(i,rotor)=0.042/Rew^0.2/(1-CoreSR)^-1.35; % 转子力矩系数 Cf_rotor=0.042/Rew^0.2/(1-CoreSR)^-1.35;
            Cf(i,stator)=0.063/Rew^0.2/CoreSR^-1.87; % 静子力矩系数Cf_stator=0.063/Rew^0.2/CoreSR^-1.87;
        else%旋流比≥1
            Cf(i,:)=[0.073/Rew^0.2 NaN 0.073/Rew^0.2 NaN]; % 力矩系数【这个公式哪来的？？】
        end

        for ii=1:length(Ct_p)%length(Ct_p)为2
            if length(rotor)==2 %若两壁面均为旋转面
                ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;%作用在转盘表面的力矩【此处的(omega_disk(ii)-omega1)与论文omega定义不同】
            elseif length(stator)==2 %若两壁面均为静止面
                ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
            elseif Ct_p(ii)==rotor
                ti(ii)=1/2*rho1*Rm^3*(omega_disk(ii)-omega1)*abs(omega_disk(ii)-omega1)*Cf(i,Ct_p(ii))*A;
            elseif Ct_p(ii)==stator
                ti(ii)=1/2*rho1*Rm^3*(0-omega1)*abs(0-omega1)*Cf(i,Ct_p(ii))*A;
            end
        end
        Tot_ti=sum(ti);%总力矩M_disk
        Swirl2=(W*Swirl1+Tot_ti)/W; %（气流的）Swirl2=Omega(air)_out*r_out^2
    end
end
GasOut.W=W;
GasOut.Pt=Pt2;%通过压力方程计算得
GasOut.Tt=Tt2;%通过温升计算得
GasOut.Swirl=Swirl2;%通过角动量守恒方程计算得
end
