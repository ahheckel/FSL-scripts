%
% nets_nodepics - view thumbnail summary images of kept and (separately) discarded nodes
% Steve Smith, 2013-2014
%
% nets_nodepics(ts,group_maps);
%
% ts: data structure containing information about nodes, timeseries and discarded nodes
% group_maps: string pointing at folder containing thumbnails (without the .sum at the end)
%

function [netmat] = nets_nodepics(ts,group_maps);

grot=tempname;

system(sprintf('slices_summary %s.sum %s.png %s',group_maps,grot,num2str(ts.DD-1)));
pic=imread(sprintf('%s.png',grot));
figure('Position',[10 10 3*size(pic,2) 3*size(pic,1)]); subplot('Position',[0 0 1 0.9]); imagesc(pic); axis off; axis equal; title('good components');

if ts.NnodesOrig~=ts.Nnodes
  system(sprintf('slices_summary %s.sum %s.png %s',group_maps,grot,num2str(setdiff(1:ts.NnodesOrig,ts.DD)-1)));
  pic=imread(sprintf('%s.png',grot));
  figure('Position',[10 100+3*size(pic,1) 3*size(pic,2) 3*size(pic,1)]); subplot('Position',[0 0 1 0.9]); imagesc(pic);  axis off; axis equal; title('bad components');
end

system(sprintf('/bin/rm %s*',grot));

