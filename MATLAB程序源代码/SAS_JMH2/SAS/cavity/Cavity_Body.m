function GasOut=Cavity_Body(GasIn,Pb,data) % W=1
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
k=data.Cons.k;%空气导热系数
omega_disk=data.boundary.RES/60*2*pi;%RES为动盘转速，单位rpm，转化为rad/s
wall_type=data.boundary.wall_type;%壁面类型：1：转径面；2：转柱面；3：转锥面；4：静径面；5：静柱面；6：静锥面；
Rout=data.Geo.PosO; % 盘腔外径
Rin=data.Geo.PosI; % 盘腔内径
G=data.Geo.G;% max(x)-min(x) 间隙
N=data.Geo.N;
face=data.Geo.face;
theta=data.Geo.theta;
l_max=size(face,2);
omega_ref=max(data.RES)/60*2*pi; % 参考转子角速度
%%
if data.direction == 1
    for i=1:N % 循环计算每个控制体的流动与换热
        R1=(face{i,2}(2)+face{i,3}(2))/2; % 控制体低位半径R1
        p12=distance_p(face{i,1},face{i,2});
        p23=distance_p(face{i,2},face{i,3});
        l=length(cell2mat(face(i,:)))/2;
        if l==l_max
            R2=(face{i,end}(2)+face{i,1}(2))/2; % 控制体高位半径R2
            p41=distance_p(face{i,end},face{i,1}); % 控制体左上角点point4到右上角点point1的距离
        else
            R2=(face{i,4}(2)+face{i,1}(2))/2; % 控制体高位半径R2
            p41=distance_p(face{i,4},face{i,1}); % 控制体左上角点point4到右上角点point1的距离
        end
        Rm=(R1+R2)/2;%控制体中心半径Rm

        A1=2*pi*R1*p23;%进口面积
        A2=2*pi*R2*p41;%出口面积
        if i==1
            Pt1=data.GasIn.Pt;
            Tt1=data.GasIn.Tt;
            % Swirl1=data.GasIn.Swirl; % 0
            CoreSR_1=data.GasIn.CoreSR; % 入口旋转比
        else
            Pt1=Pt2;%
            Tt1=Tt2;%
            CoreSR_1=SR_k;%入口旋转比=上一个控制体k的旋转比
        end
        [Ps1,Ts1,Ma1,rho1,Vr1,~]=WcalcStat(Pt1,Tt1,W,A1,data); %通过流量计算进口静态参数及Ma；Vr1：入口绝对速度
        %% 角动量守恒方程
        data.Beta(i,:)=omega_disk(i,:)/omega_ref; %正则化转子角速度
        data.omega_ref=omega_ref;data.R2=R2;data.R1=R1;data.CoreSR_1=CoreSR_1;data.rho1=rho1;
        syms SR_k;
        SR_k=CoreSR_k(i,SR_k,data);%求解i控制体的旋转比
        CoreSR_2(i)=SR_k;% i控制体出口的旋转比
        Beta(i,:)=omega_disk(i,:)/omega_ref; % 正则化转子角速度和流体角速度
        M_rotor=0;M_stator=0;
        for j=1:l
            M_r=0;M_r_cylinder=0;M_r_cone=0;M_s=0;M_s_cylinder=0;M_s_cone=0;
            switch wall_type(i,j)%计算腔任意表面的摩擦力矩
                case 1 %转径面
                    Rew=rho1*abs(Beta(i,j))*omega_ref*Rout^2/mu;%旋转雷诺数
                    cf_rotor=0.07*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                case 2 %转柱面（注意Rew内的特征尺寸选取）
                    Rew=rho1*abs(Beta(i,j))*omega_ref*data.boundary.Rh^2/mu;
                    cf_rotor=0.042*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r_cylinder=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                case 3 %转锥面(Rew和cf同转径面）
                    Rew=rho1*abs(Beta(i,j))*omega_ref*Rout^2/mu;
                    cf_rotor=0.07*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r_cone=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
                case 4 %静径面
                    Rew=rho1*omega_ref*Rout^2/mu;
                    cf_stator=0.105*(abs(SR_k))^-0.13*Rew^-0.2;
                    M_s=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                case 5 %静柱面
                    Rew=rho1*omega_ref*data.boundary.Rh^2/mu;
                    cf_stator=0.063*(abs(SR_k))^1.87*Rew^-0.2;
                    M_s_cylinder=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                case 6 %静锥面(Rew和cf同静径面）
                    Rew=rho1*omega_ref*Rout^2/mu;
                    cf_stator=0.105*(abs(SR_k))^-0.13*Rew^-0.2;
                    M_s_cone=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
            end
            M_rotor=M_rotor+M_r+M_r_cylinder+M_r_cone;
            M_stator=M_stator+M_s+M_s_cylinder+M_s_cone;
        end%若有螺栓，可在定义盘几何的函数里标记有螺栓的控制提flag=1，再加上螺栓的力矩
        %% 传热过程
        Tot_Qcell=0; % 总输入热：盘风阻和对流换热输入的热量
        Q_windage=M_rotor*omega_ref; % 风阻输入热
        Tot_Qcell=Q_windage;
        A=abs(pi*R2^2-pi*R1^2); % 控制体圆环面积

        Tf_p=find(data.boundary.htt(i,:)==1);% position 定壁温边界位置，返回索引
        hT_p=find(data.boundary.htt(i,:)==0);% position 定热流边界位置，返回索引
        n_Tf_p=length(Tf_p);% 定壁温边界数量
        n_hT_p=length(hT_p);% 定热流边界数量

        for ii=1:n_Tf_p %循环计算所有定壁温边界面的换热量
            diff_T=data.boundary.Tf(i,Tf_p(ii))-Ts1;%温差=壁面温度-入口静温； diff_T=Td-Ts1;
            if n_Tf_p==1 && Tf_p(ii)==1
                ii=ii+1;
            end
            Rew_r=rho1*(1-SR_k)*omega_ref*R2^2/mu;
            Nu=0.03*Rew_r^0.8;% 可以替换不同的经验公式
            HTCi=Nu*k/Rm;%对流换热系数h，控制体中心半径 Rm=(R1+R2)/2

            Tf_Q=HTCi*A*diff_T;
            Tot_Qcell=Tot_Qcell+Tf_Q;
        end
        for ii=1:n_hT_p %循环计算所有定热流边界面的换热量
            hT_Q=data.boundary.tH(i,hT_p(ii));%热流密度
            Tot_Qcell=Tot_Qcell+hT_Q*A;
        end
        Tt2=Tt1+Tot_Qcell/(W*cp);
        %% 动量方程
        %{
    omega1=Swirl1/R1^2;%0;气流的旋转角速度
    omega1=CoreSR_1*max(omega_disk);
    dh=(p23+p41);%【特征尺寸】0.1
    dh=(p23+p41)/2;%特征直径D；
    roughness=1/2*(data.boundary.roughness(i,1)+data.boundary.roughness(i,3));%0
    Rew=rho1*abs(omega1-max(omega_disk))*Rm^2/mu;%(使用相对于表面的流体旋转角速度)计算旋转雷诺数（取控制体中心半径）
    Rer=rho1*Vr1*dh/mu;%雷诺数

    % 压力方程
    if Rer<2000 %层流 
        f_Darch=64/Rew;% 达西摩擦因子
    elseif Rer>=4000
        f_Darch=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;%达西摩擦因子
    else
        fl=64/Rer;
        ft=0.25/(log10(roughness/(3.7*dh)+5.74/Rew^0.9))^2;
        por=(Rew-2000)/2000;
        f_Darch=por*ft+(1-por)*fl;
    end %用管道的公式计算盘腔的摩擦阻力?
    K=f_Darch*((p12+p34)/2)/dh;% Loss coefficient（与流动参数有关的摩擦损失系数K_2）： (p12+p34)/2表示控制体在流动方向上的有效长度
    Pt2=Pt1-K*W^2/(2*rho1*A1);%【压力方程？涡旋压升考虑了吗？】
        %}
        %{
    rho2=Ps2/(data.Cons.R*Ts2);
    V2=W/(rho2*A2);
    Vg2=sqrt(gamma*R*Ts2);
    Pt2=PsMa2Pstar(Ps2,Ma);
        %}
        Ps2=Ps1+rho1*SR_k*omega_ref^2*(R2^2-R1^2)/2;%rho1
        [Pt2,Ts2,Ma2,rho2,V2,~]=WcalcStat2(Ps2,Tt2,W,A2,data);
        Rew=rho2*omega_ref*Rout^2/mu;
    end
elseif data.direction == -1
    for i=N:-1:1 % 循环计算每个控制体的流动与换热
        R2=(face{i,2}(2)+face{i,3}(2))/2; % 控制体低位半径R2
        p12=distance_p(face{i,1},face{i,2});
        p23=distance_p(face{i,2},face{i,3});
        l=length(cell2mat(face(i,:)))/2;
        if l==l_max
            R1=(face{i,end}(2)+face{i,1}(2))/2; % 控制体高位半径R2
            p41=distance_p(face{i,end},face{i,1}); % 控制体左上角点point4到右上角点point1的距离
        else
            R1=(face{i,4}(2)+face{i,1}(2))/2; % 控制体高位半径R2
            p41=distance_p(face{i,4},face{i,1}); % 控制体左上角点point4到右上角点point1的距离
        end
        Rm=(R1+R2)/2;%控制体中心半径Rm

        A1=2*pi*R1*p41;%控制体高位进口面积
        A2=2*pi*R2*p23;%控制体低位出口面积
        if i==N
            Pt1=data.GasIn.Pt;
            Tt1=data.GasIn.Tt;
            % Swirl1=data.GasIn.Swirl; % 0
            CoreSR_1=data.GasIn.CoreSR; % 入口旋转比
        else
            Pt1=Pt2;%
            Tt1=Tt2;%
            CoreSR_1=SR_k;%入口旋转比=上一个控制体k的旋转比
        end
        [Ps1,Ts1,Ma1,rho1,Vr1,~]=WcalcStat(Pt1,Tt1,W,A1,data); %通过流量计算进口静态参数及Ma；Vr1：入口绝对速度
        %% 角动量守恒方程
        data.Beta(i,:)=omega_disk(i,:)/omega_ref; %正则化转子角速度
        data.omega_ref=omega_ref;data.R2=R2;data.R1=R1;data.CoreSR_1=CoreSR_1;data.rho1=rho1;
        syms SR_k;
        SR_k=CoreSR_k(i,SR_k,data);%求解i控制体的旋转比
        CoreSR_2(i)=SR_k;% i控制体出口的旋转比
        Beta(i,:)=omega_disk(i,:)/omega_ref; % 正则化转子角速度和流体角速度
        M_rotor=0;M_stator=0;
        for j=1:l
            M_r=0;M_r_cylinder=0;M_r_cone=0;M_s=0;M_s_cylinder=0;M_s_cone=0;
            switch wall_type(i,j)%计算腔任意表面的摩擦力矩
                case 1 %转径面
                    Rew=rho1*abs(Beta(i,j))*omega_ref*Rout^2/mu;%旋转雷诺数
                    cf_rotor=0.07*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                case 2 %转柱面（注意Rew内的特征尺寸选取）
                    Rew=rho1*abs(Beta(i,j))*omega_ref*data.boundary.Rh^2/mu;
                    cf_rotor=0.042*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r_cylinder=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                case 3 %转锥面(Rew和cf同转径面）
                    Rew=rho1*abs(Beta(i,j))*omega_ref*Rout^2/mu;
                    cf_rotor=0.07*sign(Beta(i,j)-SR_k)*(abs(Beta(i,j)-SR_k))^-0.65*(abs(Beta(i,j)))^0.65*Rew^-0.2;
                    M_r_cone=cf_rotor*1/2*rho1*(Beta(i,j)-SR_k)^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
                case 4 %静径面
                    Rew=rho1*omega_ref*Rout^2/mu;
                    cf_stator=0.105*(abs(SR_k))^-0.13*Rew^-0.2;
                    M_s=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5);
                case 5 %静柱面
                    Rew=rho1*omega_ref*data.boundary.Rh^2/mu;
                    cf_stator=0.063*(abs(SR_k))^-0.13*Rew^-0.2;
                    M_s_cylinder=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2*pi*data.boundary.Rh^4*data.boundary.Lh;
                case 6 %静锥面(Rew和cf同静径面）
                    Rew=rho1*omega_ref*Rout^2/mu;
                    cf_stator=0.105*(abs(SR_k))^-0.13*Rew^-0.2;
                    M_s_cone=cf_stator*1/2*rho1*SR_k^2*omega_ref^2*2/5*pi*(R2^5-R1^5)/sin(theta(i,j));
            end
            M_rotor=M_rotor+M_r+M_r_cylinder+M_r_cone;
            M_stator=M_stator+M_s+M_s_cylinder+M_s_cone;
        end%若有螺栓，可在定义盘几何的函数里标记有螺栓的控制提flag=1，再加上螺栓的力矩
        %% 传热过程
        Tot_Qcell=0; % 总输入热：盘风阻和对流换热输入的热量
        Q_windage=M_rotor*omega_ref; % 风阻输入热
       % Tot_Qcell=Q_windage;
       Tot_Qcell=abs(Q_windage);
        A=abs(pi*R2^2-pi*R1^2); % 控制体圆环面积

        Tf_p=find(data.boundary.htt(i,:)==1);% position 定壁温边界位置，返回索引
        hT_p=find(data.boundary.htt(i,:)==0);% position 定热流边界位置，返回索引
        n_Tf_p=length(Tf_p);% 定壁温边界数量
        n_hT_p=length(hT_p);% 定热流边界数量

        for ii=1:n_Tf_p %循环计算所有定壁温边界面的换热量
            diff_T=data.boundary.Tf(i,Tf_p(ii))-Ts1;%温差=壁面温度-入口静温； diff_T=Td-Ts1;
            if n_Tf_p==1 && Tf_p(ii)==1
                ii=ii+1;
            end
            Rew_r=rho1*(1-SR_k)*omega_ref*R2^2/mu;
            Nu=0.03*Rew_r^0.8;% 可以替换不同的经验公式
            HTCi=Nu*k/Rm;%对流换热系数h，控制体中心半径 Rm=(R1+R2)/2

            Tf_Q=HTCi*A*diff_T;
            Tot_Qcell=Tot_Qcell+Tf_Q;
        end
        for ii=1:n_hT_p %循环计算所有定热流边界面的换热量
            hT_Q=data.boundary.tH(i,hT_p(ii));%热流密度
            Tot_Qcell=Tot_Qcell+hT_Q*A;
        end
        Tt2=Tt1+Tot_Qcell/(W*cp);
        %% 动量方程
        Ps2=Ps1+rho1*SR_k*omega_ref^2*(R2^2-R1^2)/2;%rho1
        [Pt2,Ts2,Ma2,rho2,V2,~]=WcalcStat2(Ps2,Tt2,W,A2,data);
        Rew=rho2*omega_ref*Rout^2/mu;
    end
end
%Rew_show=rho2*omega_ref*Rout^2/mu
%C_w_show=W/(mu*Rout)
GasOut.Pt=Pt2;%通过压力方程计算得
GasOut.W=W;
GasOut.Tt=Tt2;%通过温升计算得
GasOut.CoreSR=SR_k;%通过角动量守恒方程计算得
%GasOut.HTCi=HTCi;%对流换热系数h
GasOut.rho2=rho2;
GasOut.Swirl2=SR_k*omega_ref*data.Geo.PosI^2;
GasOut.V2=V2;
end