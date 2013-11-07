%
% nets_spectra - calculate and display spectrum for each node, averaged across subjects
% Steve Smith, 2012
%
% [ts_spectra] = nets_spectra(ts); 
% [ts_spectra] = nets_spectra(ts,node_list); 
%
% node_list is optional, and is a vector listing the nodes to include
%

function [ts_spectra] = nets_spectra(ts,varargin);   % produce subject-averaged spectra

N=ts.Nnodes;
nodelist=1:N;
if nargin==2     
  nodelist=varargin{1};
  N=length(nodelist);
end

ts_spectra=[];

for s=1:ts.Nsubjects
  grot=ts.ts((s-1)*ts.NtimepointsPerSubject+1:s*ts.NtimepointsPerSubject,nodelist);
  for ii=1:N
    %ts_spectra(:,ii,s)=smooth( pwelch(grot(:,ii)) ,10,'lowess');
    ts_spectra(:,ii,s)=pwelch(grot(:,ii));
  end
end

ts_spectra=mean(ts_spectra,3);

nets_plot(ts_spectra);

