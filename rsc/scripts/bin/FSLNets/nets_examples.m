

%%% FSLNets - simple network matrix estimation and applications
%%% Stephen Smith, FMRIB Analysis Group
%%% Copyright (C) 2012 University of Oxford
%%% See documentation at  www.fmrib.ox.ac.uk/fsl


%%% change the following paths according to your local setup
addpath /home/fs0/steve/NETWORKS/FSLNets                 % wherever you've put this package
addpath /home/fs0/steve/matlab/L1precision            % L1precision toolbox
addpath /home/fs0/steve/matlab/pwling                 % pairwise causality toolbox
addpath(sprintf('%s/etc/matlab',getenv('FSLDIR')))    % you don't need to edit this if FSL is setup already


%%% setup the names of the directories containing your group-ICA and dualreg outputs
group_maps='your-group-ICA.ica/melodic_IC';     % spatial maps 4D NIFTI file, e.g. from group-ICA
   %%% you must have already run the following (outside MATLAB), to create summary pictures of the maps in the NIFTI file:
   %%% slices_summary <group_maps> 4 $FSLDIR/data/standard/MNI152_T1_2mm <group_maps>.sum
ts_dir='groupICA.dr';                           % dual regression output directory, containing all subjects' timeseries


%%% load timeseries data from the dual regression output directory
ts=nets_load(ts_dir,3,1);
   %%% arg2 is the TR (in seconds)
   %%% arg3 controls variance normalisation: 0=none, 1=normalise whole subject stddev, 2=normalise each separate timeseries from each subject
ts_spectra=nets_spectra(ts);   % have a look at mean timeseries spectra


%%% cleanup and remove bad nodes' timeseries (whichever is not listed in ts.DD is *BAD*).
ts.DD=[1 2 3 4 5 6 7 9 11 14 15 17 18];  % list the good nodes in your group-ICA output (counting starts at 1, not 0)
ts=nets_tsclean(ts);                     % regress the bad nodes out of the good, and then remove the bad nodes' timeseries
nets_pics(ts,group_maps);                % quick views of the good and bad components
ts_spectra=nets_spectra(ts);             % have a look at mean spectra after this cleanup


%%% create various kinds of network matrices and optionally convert correlations to z-stats.
%%% here's various examples - you might only generate/use one of these.
%%% the output has one row per subject; within each row, the net matrix is unwrapped into 1D.
%%% the r2z transformation estimates an empirical correction for autocorrelation in the data.
netmat0=nets_makemats(ts,'cov');                       % covariance (with variances on diagonal)
netmat0a=nets_makemats(ts,'amp');                      % amplitudes only - no correlations (just the diagonal)
netmat1=nets_r2z(ts, nets_makemats(ts,'corr') );       % full correlation (normalised covariances)
netmat2=nets_r2z(ts, nets_makemats(ts,'icov') );       % partial correlation
netmat3=nets_r2z(ts, nets_makemats(ts,'icov',0.1) );   % regularised partial, with lambda=0.1
netmat4=nets_r2z(ts, nets_makemats(ts,'icov',1) );     %                                 =1
netmat5=nets_r2z(ts, nets_makemats(ts,'icov',10) );    %                                 =10
netmat11=nets_makemats(ts,'pwling');                   % Hyvarinen's pairwise causality measure


%%% view of consistency of netmats across subjects
nets_consistency(netmat3);   % test whichever netmat you're interested in


%%% view hierarchical clustering of nodes
meanCORR=reshape(mean(netmat1),ts.Nnodes,ts.Nnodes);     % average the correlation  netmat across subjects, and reshape into square
meanPCORR=reshape(mean(netmat3),ts.Nnodes,ts.Nnodes);    % average the partial corr netmat across subjects, and reshape
%%% now make the figure; arg1 is shown below the diagonal (and drives the clustering/hierarchy); arg2 is shown above diagonal
nets_hierarchy(meanCORR,meanPCORR,ts.DD,sprintf('%s.sum',group_maps)); 


%%% cross-subject GLM, with inference in randomise (assuming you already have the GLM design.mat and design.con files).
%%% arg4 determines whether to view the corrected-p-values, with non-significant entries removed above the diagonal.
[p_uncorrected,p_corrected]=nets_glm(netmat1,'design.mat','design.con',1);  % returns matrices of 1-p
%%% OR - GLM, but with pre-masking that tests only the connections that are strong on average across all subjects.
%%% change the "8" to a different tstat threshold to make this sparser or less sparse.
%netmat=netmat3;  [grotH,grotP,grotCI,grotSTATS]=ttest(netmat);  netmat(:,abs(grotSTATS.tstat)<8)=0;
%[p_uncorrected,p_corrected]=nets_glm(netmat,'design.mat','design.con',1);


%%% simple cross-subject multivariate discriminant analyses, for just two-group cases.
%%% arg1 is whichever netmat you want to test.
%%% arg2 is the size of first group of subjects; set to 0 if you have two groups with paired subjects.
%%% outputs are: FLD, FLDmean(no covar), T, Tmax, Tthresh4, T/std, linear-SVM
[lda_percentages]=nets_lda(netmat3,36)


%%% create boxplots for the two groups for a network-matrix-element of interest (e.g., selected from GLM output)
%%% arg3 = matrix row number,    i.e. the first  component of interest (from the DD list)
%%% arg4 = matrix column number, i.e. the second component of interest (from the DD list)
%%% arg5 = size of the first group (set to -1 for paired groups)
nets_boxplots(ts,netmat3,1,7,36);
%print('-depsc',sprintf('boxplot-%d-%d.eps',IC1,IC2));  % example syntax for printing to file


