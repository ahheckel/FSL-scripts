%
% nets_boxplots(ts,netmat,IC1,IC2,Ngroup1);
% Steve Smith - 2013-2014
%
% show cross-subject boxplots, for a given "netmat" element (IC1,IC2), assuming there are two groups of subjects
%
% NGroup1 is the number of subjects in the first group; set to -1 for paired groups
%

function nets_boxplots(ts,netmat,IC1,IC2,Ngroup1);

ispaired=0;
if Ngroup1<0
  ispaired=1;
  Ngroup1=ts.Nsubjects/2;
end

sprintf('nodes (%d,%d) correspond to original components (%d,%d) (counting starting at 0)',IC1,IC2,ts.DD(IC1)-1,ts.DD(IC2)-1)

figure('position',[100 100 150 200]);

i=(IC1-1)*ts.Nnodes + IC2; 

% get values for boxplots, padding with NaN for unequal groups (otherwise boxplot doesn't work)
grot1=netmat(1:Ngroup1,i); grot2=netmat(Ngroup1+1:end,i);
grotl=max(length(grot1),length(grot2));
grot1=[grot1;nan(grotl-length(grot1),1)]; grot2=[grot2;nan(grotl-length(grot2),1)];

%%% use the following line if the groups are paired
if ispaired
  plot([grot1 grot2]','Color',[0.5 1 0.5]); 
end

hold on;  boxplot([grot1 grot2]);
set(gcf,'PaperPositionMode','auto');
set(gca,'XTick',[1 2],'XTickLabel',['A' ; 'B']);

%print('-depsc',sprintf('boxplot-%d-%d.eps',IC1,IC2));

