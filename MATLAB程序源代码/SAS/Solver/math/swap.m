function [x,y,varargout]=swap(varargin)
x=varargin{1};
temp=varargin{2};
y=varargin{1}.Pt;
x.Pt=temp;
x.Ptr=temp;
if size(varargin,2)>2
    varargout{1}=varargin{4};
    varargout{2}=varargin{3};
end
end
