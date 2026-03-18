function y = secant(f,xn_2,xn_1,maxerr,maxiter)
% secant (@(x)(x^2 + x -9),2,3.5,0.001)
% where x^2 + x -9 is function, [2,3] initial values and 0.001 is maximum
% error tolerable.

xn = (xn_2*f(xn_1) - xn_1*f(xn_2))/(f(xn_1) - f(xn_2));
% disp('xn-2              f(xn-2)                 xn-1              f(xn-1)               xn              f(xn)');
% disp(num2str([xn_2 f(xn_2) xn_1 f(xn_1) xn f(xn)],'%20.7f'));
flag = 1;
while abs(f(xn)) > maxerr
    xn_2 = xn_1;
    xn_1 = xn;
    xn = (xn_2*f(xn_1) - xn_1*f(xn_2))/(f(xn_1) - f(xn_2));
%     disp(num2str([xn_2 f(xn_2) xn_1 f(xn_1) xn f(xn)],'%20.7f'));
    flag = flag + 1;
    if(flag == maxiter)
        break;
    end
end
if flag >= maxiter
    fprintf('%s\n','方程根不存在');
    return
end
y = xn;
end
