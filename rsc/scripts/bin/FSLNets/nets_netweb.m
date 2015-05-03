%
% nets_netweb - create interactive web-page netmat viewer
% Paul McCarthy & Steve Smith, 2014
%
% THIS DOES NOT WORK IN OCTAVE BECAUSE THE OCTAVE statistics PACKAGE IS MISSING THE cluster FUNCTION
%
% nets_netweb(netF,netP,DD,sumpics,netwebdir)
%    netF is typically the full-correlation group netmat (e.g. Znet1 or Mnet1)
%    netP is typically the partial-correlation group netmat (e.g. Znet2 or Mnet2)
%    DD is the list of good nodes (e.g. ts.DD - needed to map the current set of nodes back to originals)
%    sumpics is the name of the directory containing summary pictures for each component, without the .sum suffix
%    netwebdir is the name of the output folder created to contain the netweb web pages
%
% e.g.:    nets_netweb(Znet1,Znet2,ts.DD,'groupICA_d60/melodic_IC','my_netweb')
%

function nets_netweb(netF,netP,DD,sumpics,netwebdir);

% replicate functionality from nets_hierarchy
grot=prctile(abs(netF(:)),99); netmatL=netF/grot; netmatH=netP/grot;
usenet=netmatL;  usenet(usenet<0)=0;
N=size(netmatL,1);  grot=prctile(abs(usenet(:)),99); usenet=max(min(usenet/grot,1),-1)/2;
for J = 1:N, for I = 1:J-1,   y((I-1)*(N-I/2)+J-I) = 0.5 - usenet(I,J);  end; end;
linkages=linkage(y,'ward');
set(0,'DefaultFigureVisible','off');figure;[~,~,hier]=dendrogram(linkages,0,'colorthreshold',0.75);close;set(0,'DefaultFigureVisible','on');
clusters=cluster(linkages,'maxclust',10)';

% copy javascript stuff into place
system(sprintf('mkdir -p %s; (cd %s/netjs; tar cf - *) | (cd %s; tar xf -)',netwebdir,fileparts(which('nets_netweb')),netwebdir));
NP=sprintf('%s/data/dataset1',netwebdir);
save(sprintf('%s/Znet1.txt',NP),'netF','-ascii');
save(sprintf('%s/Znet2.txt',NP),'netP','-ascii');
save(sprintf('%s/hier.txt',NP),'hier','-ascii');
save(sprintf('%s/linkages.txt',NP),'linkages','-ascii');
save(sprintf('%s/clusters.txt',NP),'clusters','-ascii');
mkdir(sprintf('%s/melodic_IC_sum.sum',NP));
for i=1:length(DD)
  system(sprintf('/bin/cp %s.sum/%.4d.png %s/melodic_IC_sum.sum/%.4d.png',sumpics,DD(i)-1,NP,i-1));
end

sprintf('now you can open the following in a web browser:  %s/index.html',netwebdir)

