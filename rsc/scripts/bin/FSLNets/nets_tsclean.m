%
% nets_tsclean - remove bad nodes, optionally regressing those out of the good (for further cleanup)
% Steve Smith and Ludo Griffanti, 2013-2014
%
% [ts] = nets_tsclean(ts,aggressive); 
%
% aggressive=0: "soft" - just deletes the bad and the unknown components
% aggressive=1: regresses the bad timeseries (not in DD or UNK) out of the good, and deletes the bad & unknown components
%
% ts.DD = list of good components
% ts.UNK = list of unknown components (gets deleted but never regressed out of good). Can be empty.
%

function [ts] = nets_tsclean(ts,aggressive);

ts.NnodesOrig=ts.Nnodes;

nongood=setdiff(1:ts.Nnodes,ts.DD); % bad or unknown components
bad=setdiff(nongood,ts.UNK); % only bad components

newts=[];
for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:); % all comp
  goodTS=grot(:,ts.DD); %good comp
  badTS=grot(:,bad); % bad components
  if aggressive == 1
    newts=[newts;goodTS-badTS*(pinv(badTS)*goodTS)];
  else
    newts=[newts;goodTS];
  end
end
ts.ts=newts;
ts.Nnodes=size(ts.ts,2);

