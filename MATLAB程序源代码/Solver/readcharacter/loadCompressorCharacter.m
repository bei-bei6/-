[filename,pathname_rel,FILTERINDEX]=uigetfile('燃机压气机特性.SMO');
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
value_surge=[];
DICTIO={'Surge Line'};
while(~feof(fid))
    InputText=textscan(fid,'%s','delimiter','\n');
    Intro=InputText{1};
    r=length(Intro);
    r0=strmatch(DICTIO(1),Intro,'exact');
end
fclose(fid);
%% 读喘振线
num_n=r-r0;
fid=fopen(str_filename,'r');
InputText=textscan(fid,'%s',r0,'delimiter','\n');%扫描前r0个数据
InputTexta=deblank(textscan(fid, '%s',num_n,'delimiter','\n'));
Intro1=InputTexta{1};
value_surge=str2num(char(Intro1));
n=value_surge(:,1);%转速
HPCdate.X_Surge_Wc=value_surge(:,3);%流量
HPCdate.Y_Surge_PR=value_surge(:,2);%压比
C=value_surge(:,4);%效率
fclose(fid);
%% 读特性
num_bta=(r-2*num_n-3)/num_n;%beta的数量
fid=fopen(str_filename,'r');
InputText=textscan(fid,'%s',2,'delimiter','\n');
eta=[];
pr=[];
wa=[];

for i=1:num_n
Intro=[];
InputText=textscan(fid,'%s',1,'delimiter','\n');%delimiter分隔符为换行
InputTexta=deblank(textscan(fid, '%s',num_bta,'delimiter','\n'));
Intro=InputTexta{1};
para=str2num(char(Intro));
pr(i,:)=para(:,1);
wa(i,:)=para(:,2);
eta(i,:)=para(:,3);
para(:,:)=[];
end
%% 保存
HPCdate.X_Beta=linspace(0,1,num_bta);
HPCdate.X_Ncor_r=n;
HPCdate.Y_Eff=eta;
HPCdate.Y_Wcor=wa;
HPCdate.Y_PR=pr;
try
    save([pwd,'/parameter/character.mat'],'HPCdate','-append')
catch
    save([pwd,'/parameter/character.mat'],'HPCdate')
end
MAP.HPC.Nc=HPCdate.X_Ncor_r;
MAP.HPC.Wc=HPCdate.Y_Wcor;
MAP.HPC.Eff=HPCdate.Y_Eff;
MAP.HPC.PR=HPCdate.Y_PR;
MAP.HPC.Rline=HPCdate.X_Beta;