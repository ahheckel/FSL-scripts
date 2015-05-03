%
% nets_groupmean - estimate group mean/one-group-t-test and consistency of netmats across runs/subjects
% Steve Smith, 2012-2014
%
% [Znet]      = nets_groupmean(netmats,make_figure);
% [Znet,Mnet] = nets_groupmean(netmats,make_figure);
%
% [Znet]      = nets_groupmean(netmats,make_figure,Nsubgroup);
% [Znet,Mnet] = nets_groupmean(netmats,make_figure,Nsubgroup);
%
% make_figure (0 or 1) controls whether to display the one-group-t-test group-level netmat and consistency figure
%
% Nsubgroup says that sets of Nsubgroup runs are from the same subject and should be averaged before cross-subject consistency estimation
%
% Znet is Z-stat from one-group t-test across subjects
% Mnet is mean netmat across subjects
%

function [Znet,Mnet]=nets_groupmean(netmats,gofigure,varargin);

Nsubgroup=1;
if nargin==3
  Nsubgroup=varargin{1};
end

Nf=sqrt(size(netmats,2));  N=round(Nf);  Nsub=size(netmats,1);

% one-group t-test
grot=netmats; DoF=Nsub-1;
if Nsubgroup>1
  clear grot;
  for i=1:Nsub/Nsubgroup
    grot(i,:)=mean(netmats((i-1)*Nsubgroup+1:i*Nsubgroup,:));
  end
  DoF=i-1;
end

%[grotH,grotP,grotCI,grotSTATS]=ttest(grot,0);  Tnet=grotSTATS.tstat;  Tnet(isfinite(Tnet)==0)=0;
Tnet = sqrt(size(grot,1)) * mean(grot) ./ std(grot); 

Mnet=mean(grot);

% Znet=sign(Tnet).*(2^0.5).*erfinv(1-2.*(betainc(DoF./(DoF+abs(Tnet).^2),DoF/2,1/2)/2));
% Znet(isinf(Znet)==1)=20*sign(Znet(isinf(Znet)==1));  % very large t values would otherwise be called infinite
Znet = zeros(size(Tnet));
Znet(Tnet>0) = -norminv(tcdf(-Tnet(Tnet>0),DoF));
Znet(Tnet<0) = norminv(tcdf(Tnet(Tnet<0),DoF));

Znetd=Znet;
if N==Nf      % is netmat square....
  Znet=reshape(Znet,N,N);
  Mnet=reshape(Mnet,N,N);
end

if gofigure>0
  figure('position',[100 100 1100 400]);
  subplot(1,2,1);
  plot(Znetd);
  if N==Nf      % is netmat square....
    Znetd=reshape(Znetd,N,N);
    if sum(sum(abs(Znetd)-abs(Znetd')))<0.00000001    % .....and symmetric
      imagesc(Znetd,[-10 10]);  colormap('jet');  colorbar;
    end
  end
  title('z-stat from one-group t-test');

  % scatter plot of each session's netmat vs the mean netmat
  subplot(1,2,2); 
  grot=repmat(mean(netmats),Nsub,1);
  scatter(netmats(:),grot(:));
  title('scatter of each session''s netmat vs mean netmat');
end

