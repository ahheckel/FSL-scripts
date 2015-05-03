%
% nets_tangentv - vectorise the covariance matrices by tangent space mapping  
% Diego Vidaurre 
% FMRIB Oxford, 2013-2014
%
% X = nets_tangentv(C,TCref);
% X = nets_tangentv(C);
%
% INPUTS
% C - array NxNxM, where N is the number of nodes and M is the number of covariance matrices
% TCref - what type of reference matrix we use for computing the mapping
%   + 1: geometric mean of the covariance matrices, in Riemannian space (default)
%   + 2: arithmetic mean of the covariance matrices 
%   + 3: identity
%
% OUTPUTS
% X - M x (N * (N-1) /2) matrix of stacked vectorised matrices

function X = nets_tangentv(C,TCref)

if nargin<2, TCref = 1; end

[N,~,M] = size(C);

if TCref == 1
    Cref = C(:,:,1);
    for i=2:M, 
        isqCref =  Cref^-0.5;
        sqCref =  Cref^0.5;
        Cref = sqCref*((isqCref*C(:,:,i)*isqCref)^(1/i))*sqCref;
    end
elseif TCref == 2
    Cref = mean(C,3);
else
    Cref = eye(N);
end

isqCref =  Cref^-0.5;
sqCref =  Cref^0.5;

X = zeros(M,N * (N+1) /2);
for i=1:M
    S =  sqCref * logm(isqCref * C(:,:,i) * isqCref) * sqCref;
    X(i,:)=S(triu(ones(N),0)==1);
end;
    
end
