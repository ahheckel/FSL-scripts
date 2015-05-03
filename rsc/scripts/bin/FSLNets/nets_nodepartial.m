%
% nets_nodepartial - replace node timeseries with node partial timeseries
% Steve Smith, 2013
%
% [new_ts] = nets_nodepartial(ts); 
%

function [newts] = nets_nodepartial(ts);

newts=ts; newts.ts=[];

for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:); % all comp
  for i=1:size(grot,2)
    TSi=nets_demean(grot(:,i));
    TSr=nets_demean(grot(:,setdiff(1:size(grot,2),i)));
    grot2(:,i)= TSi - TSr*(pinv(TSr)*TSi);
  end
  newts.ts=[newts.ts;grot2];
end

