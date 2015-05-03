%
% nets_netmats - create network matrices ("netmats") for each separate run/subject in ts
% Steve Smith, Ludo Griffanti, Roser Sala and Eugene Duff  2013-2014
%
% netmats = nets_netmats(ts,z,method);
% netmats = nets_netmats(ts,z,method,method_parameter);
%
% ts: structure containing node information including all timeseries
%     *OR* it can be a single timeXspace matrix (in which case the output netmat is square, not unwrapped)
% z: set to 1 to convert from r to z;  set to 0 to leave netmats as r
%    This is only applied for methods generating correlations.
%    For all partial correlation options, this conversion assumes no regularisation,
%       so most likely will not generate true z-stats for regularised options.
% method: a string determining which netmat estimation method to use (list below)
%
% e.g.:   netmats=nets_netmats(ts,1,'icov');
%
% The output (netmats) is a matrix of (runs/subjects) X (netmat elements), meaning that each row
% is the netmat for a given run/subject, unwrapped from the square form into a single row vector.
% So for 20 subjects and 10 nodes, netmat will be 20x10^2 = 20x100
%
% Methods:
% 'cov' - covariance (non-normalised "correlation")
% 'amp' - only use nodes' amplitudes - the individual original "netmats" are then (Nnodes X 1) and not a aquare matrix
% 'corr' - full correlation (diagonal is set to zero)
% 'rcorr' - full correlation after regressing out global mean timecourse
% 'icov' - partial correlation, optionally "ICOV" L1-regularised (if a lambda parameter is given as the next option)
%     e.g.:  netmats=nets_netmats(ts,1,'icov');      % (unregularised) partial correlation
%     e.g.:  netmats=nets_netmats(ts,1,'icov',10);   % "ICOV" L1-norm regularised partial correlation with lambda=10
%     L1-regularisation requires the L1precision toolbox from http://www.di.ens.fr/~mschmidt/Software/L1precision.html
% 'ridgep' - partial correlation using L2-norm Ridge Regression (aka Tikhonov)
%     e.g.:  netmats=nets_netmats(ts,1,'ridgep');    % default regularisation rho=0.1
%     e.g.:  netmats=nets_netmats(ts,1,'ridgep',1);  % rho=1
%

function [netmats] = nets_netmats(ts,do_rtoz,method,varargin);

INMODE=0;
if (size(ts,1) ~=1)
  grot=ts; clear ts;
  ts.Nsubjects=1;
  ts.ts=grot;
  ts.Nnodes=size(ts.ts,2);
  ts.NtimepointsPerSubject=size(ts.ts,1);
  INMODE=1;
end

N=ts.Nnodes;
just_diag=0;   % are we keeping just the amplitudes?
MethodType=0;  % not generating correlations, so never run r2z conversion

for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);

  switch lower(method)

    case {'cov','covariance','multiggm'}   % plain cov() needed to feed into multiggm
      grot=cov(grot);

    case {'amp','amplitude'}
      grot=std(grot);
      just_diag=1;   % we are keeping just the amplitudes

    case {'corr','correlation'}
      grot=corr(grot); grot(eye(N)>0)=0;
      MethodType=1;

    case {'rcorr'}   % corr() after regressing out mean timecourse
      mgrot=mean(grot,2); grot=grot- (mgrot * (pinv(mgrot)*grot));
      grot=corr(grot); grot(eye(N)>0)=0;
      MethodType=1;

    case {'icov','partial'}
      grot=cov(grot);
      if nargin==3     % simple partial correlation
        grot=-inv(grot);
      else             % ICOV L1-norm regularised partial correlation
        grot=-L1precisionBCD(grot/mean(diag(grot)),varargin{1}/1000);
      end
      grot=(grot ./ repmat(sqrt(abs(diag(grot))),1,N)) ./ repmat(sqrt(abs(diag(grot)))',N,1);  grot(eye(N)>0)=0;
      MethodType=2;

    case {'ridgep'}
      grot=cov(grot);  grot=grot/sqrt(mean(diag(grot).^2));
      if nargin==3
         rho=0.1;
      else
         rho=varargin{1};
      end
      grot=-inv(grot+rho*eye(N));
      grot=(grot ./ repmat(sqrt(abs(diag(grot))),1,N)) ./ repmat(sqrt(abs(diag(grot)))',N,1);  grot(eye(N)>0)=0;
      MethodType=2;

    case {'pwling'}
      if nargin==3
        pwl=4;
      else             
        pwl=varargin{1};
      end
      grot=pwling(grot',pwl);

    otherwise
      disp(sprintf('unknown method "%s"',method))
  end

  if just_diag==0
    netmats(s,:)=reshape(grot,1,N*N);
  else
    netmats(s,:)=grot;
  end
end

if (strcmp(method, 'multiggm'))
    if nargin==3
       rho=0.1;
    else
       rho=varargin{1};
    end
    NS = repmat(ts.NtimepointsPerSubject,1,ts.Nsubjects);
    [grotPRECISIONS grotOBJ]= learn_multitask_ggm(reshape(netmats',N,N,ts.Nsubjects), NS, rho, 20);
    for s=1:ts.Nsubjects
      grot = - reshape(grotPRECISIONS(:,:,s),N,N);
      grot=(grot ./ repmat(sqrt(abs(diag(grot))),1,N)) ./ repmat(sqrt(abs(diag(grot)))',N,1);  grot(eye(N)>0)=0;
      netmats(s,:) = reshape(grot,1,N*N);
    end
    MethodType=2;
end

if do_rtoz==1 && MethodType>0

  % quick crappy estimate of median AR(1) coefficient
  arone=[];
  for s=1:ts.Nsubjects
    grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);
    for i=1:N
      g=grot(:,i);  arone=[arone sum(g(1:end-1).*g(2:end))/sum(g.*g)];
    end
  end
  arone=median(arone);

  % create null data using the estimated AR(1) coefficient
  clear grot*; grotR=[];
  for s=1:ts.Nsubjects
    for i=1:N
      grot(1)=randn(1);
      for t=2:ts.NtimepointsPerSubject
        grot(t)=grot(t-1)*arone+randn(1);
      end
      grotts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,i)=grot;
    end
    if MethodType==1
      grotr=corr(grotts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:));
    else
      grotr=-inv(cov(grotts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:)));
      grotr=(grotr ./ repmat(sqrt(abs(diag(grotr))),1,N)) ./ repmat(sqrt(abs(diag(grotr)))',N,1);
    end
    grotR=[grotR; grotr(eye(N)<1)];
  end
  grotZ=0.5*log((1+grotR)./(1-grotR));
  RtoZcorrection=1/std(grotZ);

  netmats=0.5*log((1+netmats)./(1-netmats))*RtoZcorrection;
end

if ( INMODE == 1 )
  netmats = reshape(netmats,N,N);
end


