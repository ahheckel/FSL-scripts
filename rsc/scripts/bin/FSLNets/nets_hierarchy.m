%
% nets_hierarchy - create hierarchical clustering figure
% Steve Smith, 2012-2014
%
% [hier_order,linkages] = nets_hierarchy(netmatL,netmatH,DD,sumpics)
% [hier_order,linkages] = nets_hierarchy(netmatL,netmatH,DD,sumpics,colour_threshold)
%
%   netmatL is the net matrix shown below the diagonal, and drives the hierarchical clustering.
%           It is typically the z-stat from the one-group-t-test across all subjects' netmats
%   netmatH is the net matrix shown above the diagonal, for example partial correlation.
%   DD is the list of good nodes (needed to map the current set of nodes back to originals), e.g., ts.DD
%   sumpics is the name of the directory containing summary pictures for each component, without the .sum suffix
%   hier_order (output) is the index numbers of the good nodes, as reordered by the hierarchical clustering.
%   colour_threshold (default 0.75) specifies at what level the dendrogram colouring stops
%

function [dpRSN,yyRSN] = nets_hierarchy(netmatL,netmatH,DD,sumpics,varargin);    %%%% hierarchical clustering figure

colour_threshold=0.75;
if nargin>4
  colour_threshold=varargin{1};
end
 
%grot=prctile(abs(netmatL(:)),99); sprintf('99th%% abs value below diagonal is %f',grot)
%netmatL=netmatL/grot;
%grot=prctile(abs(netmatH(:)),99); sprintf('99th%% abs value above diagonal is %f',grot)
%netmatH=netmatH/grot;

grot1=prctile(abs(netmatL(:)),99); sprintf('99th%% abs value below diagonal is %f',grot1)
grot2=prctile(abs(netmatH(:)),99); sprintf('99th%% abs value above diagonal is %f',grot2)
grot=grot1;
netmatL=netmatL/grot;
netmatH=netmatH/grot;

usenet=netmatL;
usenet(usenet<0)=0;   % zero negative entries.....seems to give nicer hierarchies

H1=0.73; H2=0.8;    % sub-image sizes for default of 1-slice summary pics
[grotA,grotB,grotC]=fileparts(sumpics); if size(grotA,1)==0, grotA='.'; end; sumpics=sprintf('%s/%s.sum',grotA,grotB);
if exist(sumpics) > 0
  grot=imread(sprintf('%s/0000.png',sumpics));  % read the first summary image to find out how many slices are in each
  if abs((size(grot,1)/size(grot,2)-1))>0.5
    H1=0.6; H2=0.8;   % sub-image sizes for 3-slice summary pics
  end
end

figure('position',[10 10 1000 500]);  clear y;  N=size(netmatL,1);  gap=.5/(N+1);  
grot=prctile(abs(usenet(:)),99); usenet=max(min(usenet/grot,1),-1)/2;
for J = 1:N, for I = 1:J-1,   y((I-1)*(N-I/2)+J-I) = 0.5 - usenet(I,J);  end; end;
  yyRSN=linkage(y,'ward');
subplot('position',[0 H2 1 1-H2]);
  if exist('octave_config_info')~=0
    subplot('position',[gap H2 1-2*gap 1-H2]);
  end;
  [dh,dt,dpRSN]=dendrogram(yyRSN,0,'colorthreshold',colour_threshold); set(gca,'ytick',[],'TickLength',[0,0]);
  if exist('octave_config_info')==0
    set(dh,'LineWidth',3);
  end;
subplot('position',[gap 0 1-2*gap H1-0.01]); i=dpRSN;
  grot=tril(netmatL(i,i)) + triu(netmatH(i,i)); grot=max(min(grot,0.95),-0.95);  grot(eye(length(grot))>0)=Inf;
  colormap('jet');
  grotc=colormap;  grotc(end,:)=[.8 .8 .8];  colormap(grotc);  imagesc(grot,[-1 1]); axis off; daspect('auto');
grott=sprintf('%s.png',tempname);
  system(sprintf('slices_summary %s %s %s',sumpics,grott,num2str(DD(dpRSN)-1)));
  if exist(grott) == 2
    grot=imread(grott);  subplot('position',[gap H1 1-2*gap H2-H1-0.035]); imagesc(grot); axis off; system(sprintf('/bin/rm %s*',grott)); daspect('auto');
  end;
set(gcf,'PaperPositionMode','auto');

%print('-dpng',sprintf('hier.png'));

