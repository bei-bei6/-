function GasOut=Splitter(GasIn,w)

for i=1:length(w)
    GasOut{i}=GasIn;
    GasOut{i}.W= GasOut{i}.W*w(i);
end

end



