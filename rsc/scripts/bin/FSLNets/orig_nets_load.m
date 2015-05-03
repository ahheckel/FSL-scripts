%
% nets_load - load a folder full of individual runs'/subjects' node-timeseries files
% Steve Smith and Ludo Griffanti, 2013-2014
%
% ts = nets_load(indir,tr,varnorm);
% ts = nets_load(indir,tr,varnorm,Nruns);
%
% indir: string, naming a folder that contains multiple timeseries files (e.g. as output by dual_regression)
% tr: float containing TR (temporal resolution, in seconds)
% varnorm: temporal variance normalisation to apply:
%      0 = none
%      1 = normalise overall stddev for each run (normally one run/subject per timeseries file)
%      2 = normalise separately each separate timeseries from each run
% Nruns (optional, default=1): specify how many sub-runs per subject-file
%           (i.e., if sub-runs had previously been combined into single timeseries files)
%
% nets_load loads data from a dual regression output directory, whatever the name
% of the file (dr_stage1_subject*.txt or other). Files are loaded in
% alphabetical order.
% If you used dual regression standard command line, the subject order will
% be the same as .filelist, and design.mat/design.con supplied to dual_regression can be used.
%
% Otherwise, make sure the file order will be the same of the <design.mat>
% and <design.con> you will call later.
% In this case you will make later analysis easier if you name the .txt
% files in a logical order, for example so that all controls are listed
% before all patients:  
%   CON_N00300_TS.txt
%   CON_N00302_TS.txt
%   CON_N00499_TS.txt
%   PAT_N00373_TS.txt
%   PAT_N00422_TS.txt
%   PAT_N03600_TS.txt
%

function [ts] = nets_load(indir,tr,varnorm,varargin);

Nruns=1;
if nargin>3
  Nruns=varargin{1};
end

startdir=pwd;
cd(indir);

d=dir('*.txt');
Nsubjects=size(d,1);
TS=[];
for i=1:Nsubjects
  grotALL=load(d(i).name);  gn=size(grotALL,1);

  if i==1
    ts.NtimepointsPerSubject=gn;
  elseif gn ~= ts.NtimepointsPerSubject
    disp('Error: not all subjects have the same number of timepoints!');
  end
  gn=gn/Nruns;

  for ii=1:Nruns
    grot=grotALL((ii-1)*gn+1:ii*gn,:);
    grot=grot-repmat(mean(grot),size(grot,1),1); % demean
    if varnorm==1
      grot=grot/std(grot(:)); % normalise whole subject stddev
    elseif varnorm==2
      grot=grot ./ repmat(std(grot),size(grot,1),1); % normalise each separate timeseries from each subject
    end
    TS=[TS; grot];
  end
end

ts.ts=TS;
ts.tr=tr;
ts.Nsubjects=Nsubjects*Nruns;
ts.Nnodes=size(TS,2);
ts.NnodesOrig=ts.Nnodes;
ts.Ntimepoints=size(TS,1);
ts.NtimepointsPerSubject=ts.NtimepointsPerSubject/Nruns;
ts.DD=1:ts.Nnodes;
ts.UNK=[];

cd(startdir);

