function [netmat] = nets_r2z(ts,netmat);  % this converts from r2z, auto-correcting for temporal smoothness

% quick crappy estimate of median AR(1) coefficient
arone=[];
for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);
  for i=1:ts.Nnodes
    g=grot(:,i);
    arone=[arone sum(g(1:end-1).*g(2:end))/sum(g.*g)];
  end
end
arone=median(arone); %HKL: ';' added

% create null data using the estimated AR(1) coefficient
clear grot*; grotR=[];
for s=1:ts.Nsubjects
  for i=1:ts.Nnodes
    grot(1)=randn(1);
    for t=2:ts.NtimepointsPerSubject
      grot(t)=grot(t-1)*arone+randn(1);
    end
    grotts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,i)=grot;
  end
  grotr=corrcoef(grotts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:));
  grotR=[grotR; grotr(eye(ts.Nnodes)<1)];
end
grotZ=0.5*log((1+grotR)./(1-grotR));
RtoZcorrection=1/std(grotZ); %HKL: ';' added

netmat=0.5*log((1+netmat)./(1-netmat))*RtoZcorrection;

