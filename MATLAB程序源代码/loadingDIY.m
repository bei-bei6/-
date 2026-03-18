%自定义负载类型
%time为时间，P为负载所需功率（正数），P_d为设计点燃机输出功率，PT_Shaft为动力轴转速
%
if time<2
    P=1*P_d;
else
    P=0.5*P_d; 
end


% if time<2
%     P=0.5*P_d;
% else
%     P=1*P_d; 
% end

