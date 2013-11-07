function [p_uncorrected,p_corrected] = nets_glm(netmat,des,con,view);  % do cross-subject GLM on set of netmats, giving uncorrected and corrected p-values

XXX=size(netmat,2);
TTT=size(netmat,1);
Nf=sqrt(XXX);
N=round(Nf);
ShowSquare=0;
if (N==Nf)
  grot=reshape(mean(netmat),N,N);  
  if sum(sum(abs(grot-grot')))<0.00000001    % is netmat square and symmetric
    ShowSquare=1;
  end
end

fname=tempname;
save_avw(reshape(netmat',XXX,1,1,TTT),fname,'f',[1 1 1 1]);
system(sprintf('randomise -i %s -o %s -d %s -t %s -x -n 5000',fname,fname,des,con));

% how many contrasts were run?
[grot,ncon]=system(sprintf('imglob %s_vox_corrp_tstat*.* | wc -w',fname));
ncon=str2num(ncon);

if view==1
  figure; 
end

for i=1:ncon
  p_uncorrected(i,:)= read_avw(sprintf('%s_vox_p_tstat%d',fname,i));
  p_corrected(i,:)=   read_avw(sprintf('%s_vox_corrp_tstat%d',fname,i));
  [grot,FDRthresh]=system(sprintf('fdr -i %s_vox_p_tstat%d -q 0.05 --oneminusp | grep -v Probability',fname,i));
  FDRthresh=str2num(FDRthresh);

  sprintf('contrast %d, best values: uncorrected_p=%f FWE_corrected_p=%f. \nFDR-correction-threshold=%f (to be applied to uncorrected p-values)',i,1-max(p_uncorrected(i,:)),1-max(p_corrected(i,:)),FDRthresh)
  if view==1
    subplot(1,ncon,i);
    if ShowSquare==1
      grot=reshape(p_corrected(i,:),N,N);
      imagesc(grot.*(triu(grot,1)>0.95) + tril(grot));  % delete non-significant entries above the diag
    else
      plot(p_corrected(i,:));
    end
    title(sprintf('contrast %d',i));
  end
end

