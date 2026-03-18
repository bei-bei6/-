function PlotTMap(NcVec,WcArray, PRVec, EffArray, scalarcoe)
%转速、流量、压比、效率、缩放系数
linesize = 0.4;
offset = 0.02;%转速线标注的数字位置调节，0.02
SLformat = '%.2f';%转速线标注的数字保留两位小数
efflines = 10;%效率线共有几条
plim = 0.1;%将图两边拓展一下，数字越大拓展量越大，0.1
scalar = 1;%是否缩放，1为是
PlotEff = 1;%是否画效率线
s_Wc=scalarcoe(1);
s_PR=scalarcoe(2);
s_Eff=scalarcoe(3);

% PRVecMat=[];
% for i=1:size(WcArray,1)
%     PRVecMat=[PRVecMat;linspace(PRVec(1,i),PRVec(2,i),size(WcArray,2))];
% % PRVecMat=[PRVecMat;linspace(1.17461,3.77825,15)];
% end
% PRVec=PRVecMat;

%进行缩放
if scalar == 1
    WcArray =  WcArray*s_Wc;
    EffArray = EffArray*s_Eff;
    PRVec = (PRVec-1)*s_PR + 1;
end

set(gca,'fontsize',12);%设置字体大小为12，不过因为后面设了，因此不起作用
hold off;

%画流量线
plot(WcArray',PRVec','b-','Linewidth',linesize);
hold on;
%画效率线
if PlotEff ==1
    contour(WcArray,PRVec,EffArray,efflines,'ShowText','on','Linewidth',linesize,'Linecolor','m','LineStyle','--');
end

Wcmax = max(max(WcArray));
PRmax = max(max(PRVec));
Wcmin = min(min(WcArray));
PRmin = min(min(PRVec));
PRadj = (PRmax - PRmin) * offset;
%标注转速线
for j=1:length(WcArray(:,1))
    xmax=max(WcArray(j,:));
    ymax=max(PRVec(j,:)) + PRadj;
    strmin = num2str(NcVec(j),SLformat);
    text(xmax,ymax,strmin,'HorizontalAlignment','left','fontsize',8);
end

grid on;
xlabel('$\dot m$, kg/s','Interpreter','latex')
ylabel('\pi_T');
set(gca,'Fontname','Times New Roman','FontSize',14);
%拓展图片
Wcadjp = (Wcmax - Wcmin) * plim;
PRadjp = (PRmax - PRmin) * plim;

ylim([PRmin-PRadjp PRmax+PRadjp])
xlim([Wcmin-Wcadjp Wcmax+Wcadjp])

