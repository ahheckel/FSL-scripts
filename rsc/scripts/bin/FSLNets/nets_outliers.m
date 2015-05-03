%
% nets_outliers - identify potential outlier nodes and subjects
% Steve Smith, 2013
%
% [outlier_nodes,outlier_subjects] = nets_outliers(ts);
% [outlier_nodes,outlier_subjects] = nets_outliers(ts,Nsubgroup);
%
% Nsubgroup says that sets of Nsubgroup runs are from the same subject and should be combined before cross-subject consistency estimation
%

function [outlier_nodes,outlier_subjects,amplitudes]=nets_outliers(ts,varargin);

Nsubgroup=1;
if nargin==2
  Nsubgroup=varargin{1};
end

ts.NtimepointsPerSubject=ts.NtimepointsPerSubject*Nsubgroup;
ts.Nsubjects=ts.Nsubjects/Nsubgroup;

for s=1:ts.Nsubjects
  amplitudes(s,:)=std(ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,:));
end

amps=amplitudes./repmat(median(amplitudes),ts.Nsubjects,1); outlier_nodes=max(amps)>5;
amps=amplitudes./repmat(median(amplitudes,2),1,ts.Nnodes); outlier_subjects=max(amps,[],2)>4;

