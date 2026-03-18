function [value,isterminal,direction]=Pipe_eventfun(t,y,data)
R=data.Cons.R;
gamma=data.Cons.gamma;
value=1-y(2)./sqrt(gamma.*R.*y(3));
%% 终止条件
isterminal=1;   % 终止

%% 过零方向
% direction= 1;   %正方向，value递增方式过0
direction=-1;     % 负方向，value递减方式过0

end