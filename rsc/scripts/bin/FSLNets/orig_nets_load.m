function [ts] = nets_load(indir,tr,varnorm);
% %%% load data from a dual regression output directory, whatever the name
% of the file (dr_stage1_subject%.txt or other). Files are loaded in
% alphabetical order.
% If you used dual regression standard command line, the subject order will
% be the same of .filelist and design.mat/design.con can be applied.
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

%varnorm: 0=none,
%         1=normalise whole subject stddev,
%         2=normalise each separate timeseries from each subject 

startdir=pwd;
cd(indir);

d=dir('*.txt');
Nsubjects=size(d,1);
TS=[];
for i=1:Nsubjects
    grot=load(d(i).name);
    grot=grot-repmat(mean(grot),size(grot,1),1); % demean
    if varnorm==1
      grot=grot/std(grot(:)); % normalise whole subject stddev
    elseif varnorm==2
      grot=grot ./ repmat(std(grot),size(grot,1),1); % normalise each separate timeseries from each subject
    end
    TS=[TS; grot];
end

ts.ts=TS;
ts.tr=tr;
ts.Nsubjects=Nsubjects;
ts.Nnodes=size(TS,2);
ts.NnodesOrig=ts.Nnodes;
ts.Ntimepoints=size(TS,1);
ts.NtimepointsPerSubject=ts.Ntimepoints/ts.Nsubjects;
ts.DD=1:ts.Nnodes;

cd(startdir);

