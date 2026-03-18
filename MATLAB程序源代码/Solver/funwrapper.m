function F= funwrapper(aircraft, x,data)
F = aircraft(x,data);
F = F(:);
end