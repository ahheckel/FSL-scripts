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

function [p_uncorrected,p_corrected] = nets_glm(netmats,des,con,view,varargin); 

nperms=5000;
if nargin==5
  nperms=varargin{1};
end 

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

fname=tempname;
save_avw(reshape(netmats',XXX,1,1,TTT),fname,'f',[1 1 1 1]);
system(sprintf('randomise -i %s -o %s -d %s -t %s -x --uncorrp -n %d',fname,fname,des,con,nperms));

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

  sprintf('contrast %d, best values: uncorrected_p=%f FWE_corrected_p=%f. \nFDR-correction-threshold=%f (to be applied to uncorrected p-values)',i,1-max(p_uncorrected(i,:)),1-max(p_corrected(i,:)),FDRthresh)
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

