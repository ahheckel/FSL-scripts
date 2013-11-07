function [lda_percentages,grot] = nets_lda(x,A);  % x = subjects X measurements
               % A is number of subjects in first group; set to 0 for paired data

x=x';
grot=[]; % misc return variable

% x=read_avw('all_FA_skeletonised_cut');
% A=25;       % size of first group
% N=size(x,4)
% x=reshape(x,size(x,1)*size(x,2)*size(x,3),N);
% m=std(x,0,2);
% x=x(find(m>0),:);
% x=demean(x,2);
% sslda(x,A);

N=size(x,2);
m=std(x,0,2);
x=x(find(m>0),:);
x=demean(x,2);

if A==0
  ALL=1:N/2;
  for n=1:N/2
    x(:,[n n+N/2]) = demean(x(:,[n n+N/2]),2);
  end
else
  ALL=1:N;
end

for n = ALL
  if A==0
    xa=x(:,setdiff(1:N/2,n));
    xb=x(:,setdiff(N/2+1:N,n+N/2));
  else
    xa=x(:,setdiff(1:A,n));
    xb=x(:,setdiff(A+1:N,n));
  end

  E=[demean(xa,2) demean(xb,2)];
  Estd=std(E,0,2);

  meana=mean(xa,2);
  meanb=mean(xb,2);
  deltamean = meana-meanb;

  [u,s,v]=svd(E,'econ');
  ps=pinv(s);
  w=u*ps*ps*(u'*deltamean);
  xx=x(:,n) - 0.5*(meana+meanb);
  t=sqrt(N-2)*deltamean./Estd;
  [mmm,iii]=max(abs(t)); best_t_i(n)=iii;

  svmstruct = svmtrain([xa xb]',[ ones(size(xa,2),1) ; zeros(size(xb,2),1) ]);

  lda(1,n)=w'* xx;                            % FLD
  lda(2,n)=deltamean'*xx;                     % FLD mean (ignore covariance)
  lda(3,n)=t'*xx;                             % T
  lda(4,n)=t(iii)*xx(iii);                    % Tmax
  lda(5,n)=(t.*(abs(t)>4))'*xx;               % Tthresh
  lda(6,n)=(deltamean./(Estd.*Estd))'*xx;     % T/std
  lda(7,n)=svmclassify(svmstruct,xx')*2-1;    % SVM
end

if A==0
  lda_percentages = 100* ( sum(lda>0,2) )' / length(ALL);
else
  lda_percentages = 100* ( sum(lda(:,1:A)>0,2) + sum(lda(:,A+1:N)<0,2) )' / length(ALL);
end

