%
% [p_uncorrected,p_corrected] = nets_glm(netmats,design_matrix,contrast_matrix,view_output);
% [p_uncorrected,p_corrected] = nets_glm(netmats,design_matrix,contrast_matrix,view_output,nperms);
% Steve Smith and Ludo Griffanti - 2013-2014
%
% do cross-subject GLM on a set of netmats, giving uncorrected and corrected (1-p) values
%   randomise(permutation testing) is used to get corrected 1-p-values (i.e., correcting for multiple comparisons
%   across the NxN netmat elements)
%
% design_matrix and contrast_matrix are strings pointing to randomise-compatible design and contrast matrix files
%
% view_output (0 or 1) determines whether to bring up the graphical display of the results.
%   below the diagonals is shown the 1-corrected-p,
%   above the diagonal is the same thing, but thresholded at 0.95 i.e. corrected-p < 0.05
%

function [p_uncorrected,p_corrected] = nets_glm(netmats,des,con,grp,nperm,view,path); % added grp, nperm and path argument (HKL)

%nperms=5000;
%if nargin==5
%  nperms=varargin{1};
%end % commented out (HKL)

XXX=size(netmats,2);
TTT=size(netmats,1);
Nf=sqrt(XXX);
N=round(Nf);
ShowSquare=0;
if (N==Nf)
  grot=reshape(mean(netmats),N,N);  
  if sum(sum(abs(grot-grot')))<0.00000001    % is netmat square and symmetric
    ShowSquare=1;
  end
end

%fname=tempname; % commented out by HKL
mkdir(path); % create output dir. (HKL)
fname=strcat(path,'/FSLNETRAND'); % define input to randomise (HKL)
disp(fname)
mask=strcat(path,'/FSLNET_mask'); % define mask (HKL)
disp(mask)
system(sprintf('rm -fv %s',fname)); % delete prev. input (HKL)
system(sprintf('rm -fv %s',mask)); % delete prev. mask (HKL)
system(sprintf('rm -fv %s_vox_*tstat*.nii.gz',fname)); % delete prev. results (HKL)

save_avw(reshape(netmats',XXX,1,1,TTT),fname,'f',[1 1 1 1]);
disp(sprintf('fslmaths %s -abs -bin %s', fname, mask)) % make mask for randomise in FSL < v5 (HKL)
system(sprintf('fslmaths %s -abs -bin %s', fname, mask)); % make mask for randomise in FSL < v5 (HKL)

%F-contrast file present ? (HKL)
[a,b,c]=fileparts(con);
fcon=sprintf('%s/%s%s',a,b,'.fts');
if exist(fcon, 'file')==2
    disp('F-test contrast file found:')
    disp(sprintf('%s',fcon))
    fopts=sprintf('-f %s',fcon);
else
    fopts='';
end

%system(sprintf('randomise -i %s -o %s -d %s -t %s -x --uncorrp -n %d',fname,fname,des,con,nperms)); % commented out (HKL)
disp(sprintf('randomise -i %s -m %s -o %s -d %s -t %s -e %s %s -x -n %i', fname,mask,fname,des,con,grp,fopts,nperm))  % -e added (HKL)
system(sprintf('randomise -i %s -m %s -o %s -d %s -t %s -e %s %s -x -n %i 1>/dev/null',fname,mask,fname,des,con,grp,fopts,nperm));  % -e added (HKL)

% how many contrasts were run?
[grot,ncon]=system(sprintf('imglob %s_vox_corrp_tstat*.* | wc -w',fname));
ncon=str2num(ncon);

if view==1
  figure('position',[100 100 600*ncon 500]); 
end

gap=0.05; cw=0.1;  xw=(1-gap*(ncon+2))/(ncon+0.1);

for i=1:ncon
  p_uncorrected(i,:)= read_avw(sprintf('%s_vox_p_tstat%d',fname,i));
  p_corrected(i,:)=   read_avw(sprintf('%s_vox_corrp_tstat%d',fname,i));
  [grot,FDRthresh]=system(sprintf('fdr -i %s_vox_p_tstat%d -q 0.05 --oneminusp | grep -v Probability',fname,i));
  FDRthresh=str2num(FDRthresh);
  
  % find max. uncorrected p-val - HKL
  mpu=max(p_uncorrected(i,:));
  idx_u=find(p_uncorrected(i,:)>=mpu);
  
  % find max. corrected p-val - HKL
  mpc=max(p_corrected(i,:));
  idx_c=find(p_corrected(i,:)>=mpc);

  sprintf('contrast %d, best values: uncorrected_p=%f FWE_corrected_p=%f \nFDR-correction-threshold=%f (to be applied to uncorrected p-values)',i,1-max(p_uncorrected(i,:)),1-max(p_corrected(i,:)),FDRthresh) % commented out (HKL)
  %disp(sprintf('contrast %d, best values: uncorrected_p=%f (at %i) FWE_corrected_p=%f (at %i). \nFDR-correction-threshold=%f (to be applied to uncorrected p-values)',i,1-max(p_uncorrected(i,:)),idx_u,1-max(p_corrected(i,:)),idx_c,FDRthresh)) % added (HKL)
  
  if view==1
    if ShowSquare==1
      if (i<ncon)
        subplot('Position',[ (i-1)*xw+i*gap gap xw 1-2*gap ]);
      else
        subplot('Position',[ (i-1)*xw+i*gap gap xw+0.1 1-2*gap ]);
      end
      grot=reshape(p_corrected(i,:),N,N);
      [groti,grotj]=find(grot==max(grot(:)));
      sprintf('optimal corrected p=%.5f at edge between nodes %d and %d\n',1-max(grot(:)),groti(1),grotj(1))
      imagesc(grot.*(triu(grot,1)>0.95) + tril(grot));  % delete non-significant entries above the diag
      colormap('jet');
      if (i==ncon),  colorbar;  end;
    else
      subplot('Position',[ (i-1)*xw+i*gap gap xw 1-2*gap ]);
      plot(p_corrected(i,:));
    end
    title(sprintf('contrast %d',i));
  end
end

