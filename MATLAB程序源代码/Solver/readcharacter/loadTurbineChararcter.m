% --- Executes on button press in pushbutton2.
% function pushbutton2_Callback(hObject, eventdata, handles)% hObject handle to pushbutton2 (see GCBO)
% eventdata reserved - to be defined in a future version of MATLAE% handles structure with handles and user data (see GUIDATA) 
[filename,pathname_rel,FILTERINDEX]=uigetfile('燃机涡轮特性.SMO');
if(FILTERINDEX==0)
    return;
end
str_filename=[pathname_rel,filename];
fid=fopen(str_filename,'r');
if(fid==-1)
    errordlg('打开文件出错','Open error');
    return;
end

%% 读取信息行
while(~feof(fid))
    InputText=textscan(fid, '%s','delimiter','\n');
    r=length(InputText{1});
end
fclose(fid);
%% 读表头
fid=fopen(str_filename,'r');
Title=textscan(fid,'%s',8,'delimiter','\n');
num_n=textscan(fid,'%f',1,'delimiter','\n');
num_n= num_n{1};%转速线的数量
none=textscan(fid,'%s',1,'delimiter','\n');
%% 读特性参数
num_bta=(r-9)/num_n-1;%beta线的数量
eta=[];
pr=[];
wa=[];
n=[];
for i=1:num_n
InputText=textscan(fid,'%s',1,'delimiter','\n');
InputTexta=deblank(textscan(fid, '%s' ,num_bta,'delimiter','\n'));
para=str2num(char(InputTexta{1}));
cn=str2num(char(InputText{1}));
n(i)=cn(1);
pr(i,:)=para(:,2);
wa(i,:)=para(:,1)*101325/sqrt(288.15);
eta(i,:)=para(:,3);
cn=[];
end