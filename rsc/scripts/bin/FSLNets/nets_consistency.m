function [Tnet]=nets_consistency(netmat);

figure;
Nf=sqrt(size(netmat,2));
N=round(Nf);
Nsub=size(netmat,1);

% one-group t-test
[grotH,grotP,grotCI,grotSTATS]=ttest(netmat);
Tnet=grotSTATS.tstat;
subplot(1,2,1);
plot(Tnet);
if N==Nf      % is netmat square....
  Tnet=reshape(Tnet,N,N);
  Tnet(eye(N)>0)=0;
  if sum(sum(abs(Tnet)-abs(Tnet')))<0.00000001    % .....and symmetric
    imagesc(Tnet,[-10 10]);
  end
end
title('one-group t-test');
colorbar;

% scatter plot of each session's netmat vs the mean netmat
subplot(1,2,2); 
grot=repmat(mean(netmat),Nsub,1);
scatter(netmat(:),grot(:));
title('scatter of each session''s netmat vs mean netmat');

