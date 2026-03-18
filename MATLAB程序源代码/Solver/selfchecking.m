if exist('.\整机性能模型', 'dir') ...
    && exist('.\Solver', 'dir') ...
    && exist('.\thermo', 'dir') ...
    && exist('.\IFC67', 'dir') ...
    && exist('.\Generator', 'dir') ...
    && exist('.\parameter', 'dir')

    addpath(genpath('.\整机性能模型'));
    addpath(genpath('.\Solver'));
    addpath(genpath('.\thermo'));
    addpath(genpath('.\IFC67'));
    addpath(genpath('.\Generator'));
    addpath(genpath('.\parameter'));
    addpath(genpath('.\SAS_JMH2'));
else
    error('程序文件缺失');
end