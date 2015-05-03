%MENTAPPR: Compute MaxEnt approximation of negentropy and differential entropy
%Aapo Hyvarinen, May 2012
%Based on NIPS*97 paper, www.cs.helsinki.fi/u/ahyvarin/papers/NIPS97.pdf
%  but using a new nonlinearity
%Input: sample of continous-valued random variable as a vector. 
%        For matrices, entropy computed for each column
%Output: (differential) entropy and, optionally, negentropy

function [entropy,negentropy]=mentappr(x)

%standardize 
x=x-mean(x);
xstd=std(x);
x=x/xstd;

%Constants we need
k1=36/(8*sqrt(3)-9);
gamma=0.37457; 
k2=79.047;
gaussianEntropy=log(2*pi)/2+1/2;

%This is negentropy
negentropy = k2*(mean(log(cosh(x)))-gamma)^2+k1*mean(x.*exp(-x.^2/2))^2;

%This is entropy
entropy = gaussianEntropy - negentropy + log(xstd);

