function data=wrapdata(data,varargin)
for i=1:length(varargin)
    name{i}=inputname(i+1);
    eval(['data','.',name{i},'=',num2str(varargin{i}),';']);
end
end