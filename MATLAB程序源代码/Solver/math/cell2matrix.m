function M=cell2matrix(G)
M=[];
for i=1:length(G)
    M=cat(1,M,G{i});
end
end