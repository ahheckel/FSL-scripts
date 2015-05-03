% goes from a Nx1 vector of q different classes (Y) 
% to a Nxq matrix of dummy variables encoding the same 
function Ym = nets_class_vectomat(Y)
N = length(Y); uY = unique(Y); q = length(uY);
Ym = zeros(N,q);
for j=1:q, Ym(Y==uY(j),j) = 1; end 
