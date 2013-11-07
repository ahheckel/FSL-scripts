function [netmat] = nets_makemats(ts,method,varargin);

N=ts.Nnodes;
just_diag=0;   % are we keeping just the amplitudes?

for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);

  switch lower(method)
    case {'cov','covariance'}
      grot=cov(grot);
    case {'amp','amplitude'}
      grot=std(grot);
      just_diag=1;   % we are keeping just the amplitudes
    case {'corr','correlation'}
      grot=corrcoef(grot); grot(eye(N)>0)=0;
    case {'icov','partial'}
      grot=cov(grot);
      if nargin==2     % simple partial correlation
        grot=-inv(grot);
      else             % ICOV L1-norm regularised partial correlation
        grot=-L1precisionBCD(grot/mean(diag(grot)),varargin{1}/1000);
      end
      grot=(grot ./ repmat(sqrt(abs(diag(grot))),1,N)) ./ repmat(sqrt(abs(diag(grot)))',N,1);
      grot(eye(N)>0)=0;
    case {'pwling'}
      if nargin==2     
        pwl=4;
      else             
        pwl=varargin{1};
      end
      grot=pwling(grot',pwl);
    otherwise
      disp(sprintf('unknown method "%s"',method))
  end

  if just_diag==0
    netmat(s,:)=reshape(grot,1,N*N);
  else
    netmat(s,:)=grot;
  end
end

