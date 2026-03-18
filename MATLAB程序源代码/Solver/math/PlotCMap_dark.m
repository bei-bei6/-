function PlotCMap_dark(NcVec, WcArray, PRArray, EffArray, Rline, scalarcoe)
linesize=0.4;
offset = 0.02;
SLformat = '%.2f';
surgesize=2.5;
plim = 0.1;
efflines=10;
defSline = 1;
scalar = 1;
PlotRline = 1;
PlotNc = 1;
PlotEff = 1;
%%
s_Wc=scalarcoe(1);
s_PR=scalarcoe(2);
s_Eff=scalarcoe(3);
%%
LenNc = length(NcVec);
LenRline = length(Rline);
ColWc = size(WcArray,2);
ColPR = size(PRArray,2);
RowWc = size(WcArray,1);
RowPR = size(PRArray,1);
if (LenNc == RowPR && LenNc == RowWc && LenRline == ColWc && LenRline == ColPR)
    for i = 1:LenNc
        PRstallMap(i) = interp2(Rline , NcVec,  PRArray, 1, NcVec(i));
        SM_Wc(i) = interp2(Rline ,NcVec,  WcArray, 1, NcVec(i));
    end
end
%%
if scalar == 1
    WcArray =  WcArray*s_Wc;
    EffArray = EffArray*s_Eff;
    PRArray = (PRArray-1)*s_PR + 1;
    if defSline == 1
        SM_Wc = SM_Wc * s_Wc;
        PRstallMap = (PRstallMap - 1)*s_PR + 1;
    end
end

set(gca,'fontsize',12);
hold off;
%beta线
% if PlotRline ==1
%     plot(WcArray,PRArray,'c-','Linewidth',linesize);
%     hold on;
% end

if PlotNc ==1
    plot(WcArray',PRArray','b-','Linewidth',linesize);
    hold on;
end
%效率线
if PlotEff ==1
%     contour(WcArray,PRArray,EffArray,efflines,'ShowText','on','Linewidth',linesize*2,'Linecolor','k','LineStyle','--');
    contour(WcArray,PRArray,EffArray,efflines,'ShowText','off','Linewidth',linesize*2,'Linecolor','k','LineStyle','--');
    hold on;
end

if (defSline == 1)
    plot(SM_Wc,PRstallMap,'r-','Linewidth',surgesize);
end


Wcmax = max(max(WcArray));
PRmax = max(max(PRArray));
Wcmin = min(min(WcArray));
PRmin = min(min(PRArray));

if PlotNc ==1
    Wcadj = (Wcmax - Wcmin) * offset;
    PRadj = (PRmax - PRmin) * offset;
    
    for j=1:length(WcArray(:,1))
        xmax=WcArray(j,1)- Wcadj;
        ymax=PRArray(j,1)+ PRadj;
        strmin = num2str(NcVec(j),SLformat);
        text(xmax,ymax,strmin,'HorizontalAlignment','left','fontsize',8);
    end
end


grid on;
xlabel('$\dot m$, kg/s','Interpreter','latex')
ylabel('\pi_C');
set(gca,'Fontname','Times New Roman','FontSize',14);
% title(MapName);

Wcadjp = (Wcmax - Wcmin) * plim;
PRadjp = (PRmax - PRmin) * plim;

ylim([PRmin-PRadjp PRmax+PRadjp])
xlim([Wcmin-Wcadjp Wcmax+Wcadjp])
set(findobj('Type','line'),'Color','k')
