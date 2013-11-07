function [ts] = nets_tsclean(ts);   % regress the bad timeseries (not listed in DD) out of the good, and delete the bad

ts.NnodesOrig=ts.Nnodes;

%%% do all subjects as one
%grot=ts.ts(:,ts.DD);
%xx=ts.ts(:,setdiff(1:ts.Nnodes,ts.DD));
%ts.ts=grot-xx*(pinv(xx)*grot);

newts=[];
for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:);
  grot1=grot(:,ts.DD);
  xx=grot(:,setdiff(1:ts.Nnodes,ts.DD));
  newts=[newts;grot1-xx*(pinv(xx)*grot1)];
end
ts.ts=newts;

ts.Nnodes=size(ts.ts,2);

