function h = circle(x,y,r,theta1,theta2)
hold on
th = theta1/180*pi:pi/50:theta2/180*pi;
xunit = r * cos(th) + x;
yunit = r * sin(th) + y;
h = plot(xunit, yunit,'-b','LineWidth',1);
hold off