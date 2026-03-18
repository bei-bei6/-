function CerrC(boundary,htt,Tf,tH,rou,Ct)
%
if ~isempty(find(boundary~=0 & boundary~=1 & boundary~=5,1)==1)
    error('边界类型设置错误，仅支持[0 1 5]型')
end
%
if any(~isnan(htt(boundary==5))==1)
    error('流体传热边界设置错误，必须为NaN')
end
if ~isempty(find(unique(htt(~isnan(htt)))~=0 & unique(htt(~isnan(htt)))~=1,1)==1)
    error('壁面传热边界设置错误，仅支持[0 1]')
end
%
if any(~isnan(Tf(htt~=1))==1)
    error('非给定壁面温度边界必须为NaN')
end
%
if any(~isnan(tH(htt~=0))==1)
    error('非给定壁面热流边界必须为NaN')
end
%
if any(~isnan(rou(boundary==5))==1)
    error('流体面粗糙度必须给定NaN')
end
if any(~isnan(rou(boundary~=5))==0)
    error('壁面必须给定粗糙度')
end
%
end