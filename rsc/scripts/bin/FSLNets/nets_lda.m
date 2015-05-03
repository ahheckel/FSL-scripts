%
% lda_percentage = nets_lda(x,A,nmethod);
% Steve Smith - 2013-2014
%
% apply one of a number of linear classifiers to the two-group data
% returning the classifiction accuracy found using LOO testing
%
% x = subjects X measurements  - for example a "netmats" matrix, with two "groups" of ordered subjects
% A is number of subjects in first group; set to 0 for paired data
%
% nmethod:
%  1 FLD
%  2 FLD-mean (ignore covariance)
%  3 two-group T weighting
%  4 two-group maximum-T weighting
%  5 two-group thresholded-T weighting
%  6 two-group T/stddev weighting
%  7 Matlab's built-in SVM
%  8 LIBSVM's SVM - need to have libsvm installed
%

function [lda_percentages,grot] = nets_lda(x,A,nmethod);  

x=x';
grot=[]; % misc return variable
N=size(x,2);
m=std(x,0,2);
x=x(find(m>0),:);

if A==0
  ALL=1:N/2;
  for n=1:N/2
    x(:,[n n+N/2]) = nets_demean(x(:,[n n+N/2]),2);
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

  E=[nets_demean(xa,2) nets_demean(xb,2)];  Estd=std(E,0,2);  [u,s,v]=svd(E,'econ');  ps=pinv(s);
  meana=mean(xa,2);  meanb=mean(xb,2);  deltamean = meana-meanb; meanab=0.5*(meana+meanb);
  w=u*ps*ps*(u'*deltamean);
  xx=x(:,n) - meanab;
  xxn= (x(:,n) - meanab) ./ Estd;
  xan=(xa-repmat(meanab,1,size(xa,2)))./repmat(Estd,1,size(xa,2));
  xbn=(xb-repmat(meanab,1,size(xb,2)))./repmat(Estd,1,size(xb,2));
  t=sqrt(N-2)*deltamean./Estd;
  [mmm,iii]=max(abs(t)); best_t_i(n)=iii;

  if nmethod==1
    lda(1,n)=w'* xx;                            % FLD
  elseif nmethod==2
    lda(1,n)=deltamean'*xx;                     % FLD mean (ignore covariance)
  elseif nmethod==3
    lda(1,n)=t'*xx;                             % T
  elseif nmethod==4
    lda(1,n)=t(iii)*xx(iii);                    % Tmax
  elseif nmethod==5
    lda(1,n)=(t.*(abs(t)>4))'*xx;               % Tthresh
  elseif nmethod==6
    lda(1,n)=(deltamean./(Estd.*Estd))'*xx;     % T/std
  elseif nmethod==7                             % matlab svm
    svmstruct = svmtrain([xan xbn]',[ ones(size(xa,2),1) ; zeros(size(xb,2),1) ]);
    %figure; plot(svmstruct.ScaleData.shift); figure; plot(svmstruct.ScaleData.scaleFactor)
    lda(1,n)=svmclassify(svmstruct,xxn')*2-1;
  elseif nmethod==8                             % LIBSVM svm
    svmstruct = svmtrain([ ones(size(xa,2),1) ; zeros(size(xb,2),1) ], [xan xbn]' , '-q -t 0');  % change to "-t 2" for RBF nonlinear SVM
    [grot,~,~]=svmpredict(1,xxn',svmstruct,'-q'); lda(1,n)=grot*2-1;
  end

end

if A==0
  lda_percentages = 100* ( sum(lda>0,2) )' / length(ALL);
else
  lda_percentages = 100* ( sum(lda(:,1:A)>0,2) + sum(lda(:,A+1:N)<0,2) )' / length(ALL);
end

