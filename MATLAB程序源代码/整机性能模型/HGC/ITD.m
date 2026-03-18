function sigma=ITD(L_itd,AR_itd,Mach,blade)%叶片的存在将造成涡轮损失翻倍%涡轮几何参数决定几何结构%进口MACH数与气流角修正工况
    %测试算例
%     L_itd=8
%     AR_itd=1.2
%     Mach=0.25
%     blade=1
    %% 参考工况 参数化几何性能
    W=L_itd;
    AR_itd=AR_itd;
    % syms x y
    
    p1=-2459.73217805055;p2=604.023044414827;p3=241.456901906748;p4=460.087569689435;p5=34.8313602530166;p6=-34.126516189222;p7=2.55276479939082;p8=106.973731094972;
    p9=-90.8283072112523;p10=-38.737027937209;
    f=@(W,AR)(W.*AR./(p1+p2.*W+p3.*AR+p4.*W.^2+p5.*AR.^2+p6.*W.^3+p7.*AR.^3+p8.*W.*AR+p9.*W.^2.*AR+p10.*W.*AR.^2));
    
    
    geo=(1-((f(L_itd,AR_itd)>=1)*f(L_itd,AR_itd)+(f(L_itd,AR_itd)<1)*f(L_itd,AR_itd)))/2;
    %% 根据参考工况进行工况修正\
    %0.3MAch为参考点
    loss=(Mach/0.3)*geo*(Mach<0.3)+(Mach/0.3)^2*geo*(Mach>=0.3);
    
    %% 有无叶片%损失翻倍
    if blade==1
        loss=2*loss;
    end
    %% 总压恢复
    sigma=1-loss;
end
