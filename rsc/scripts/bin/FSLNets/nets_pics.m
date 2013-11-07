function [netmat] = nets_pics(ts,group_maps);    %%%% show a snapshot of the kept and rejected components

system(sprintf('slices_summary %s.sum grot.png %s',group_maps,num2str(ts.DD-1)));
picgood=imread('grot.png'); figure; imagesc(picgood); axis off; title('good components');

if ts.NnodesOrig~=ts.Nnodes
  system(sprintf('slices_summary %s.sum grot.png %s',group_maps,num2str(setdiff(1:ts.NnodesOrig,ts.DD)-1)));
  picbad=imread('grot.png'); figure; imagesc(picbad);  axis off; title('bad components');
end

