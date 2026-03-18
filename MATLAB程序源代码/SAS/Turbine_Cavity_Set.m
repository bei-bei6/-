function [Geo,boundary]=Turbine_Cavity_Set(BC,N)
Td=BC.Td;
x=[0.05 0.05 0 0];
y=[0.1 0.05 0.05 0.1];
node=[];
PosO=0.1;
PosI=0.05;

type=5*ones(N,4);%指定边界类型,默认为流体面
for i=1:N
    type(i,:)=[0,5,1,5]; % 0: 静止 1: 旋转,5流体面
    htt(i,:)=[1,NaN,0,NaN];% 0: 给定热流，1: 给定壁面温度
    Tf(i,:)=[Td,NaN,NaN,NaN];
    tH(i,:)=[NaN,NaN,0,NaN];
    roughness(i,:)=[0,NaN,0,NaN];
end
boundary.type=type;
boundary.htt=htt;
boundary.Tf=Tf;
boundary. tH=tH;
boundary.roughness=roughness;

Geo=TDC(N,x,y,node,PosI,PosO,boundary,0);

end