function f = annot_query(labelfile, annotfile, out)

% Written by Andreas Heckel
% University of Freiburg
% heckelandreas@googlemail.com
% https://github.com/ahheckel
% 05/18/2015

%labelfile='/home/andi/projects/biller/cr.label';
%annotfile='/usr/local/freesurfer/subjects/fsaverage/label/lh.aparc.a2009s.annot';
%out='a.txt';

% 
% if(nargin ~= 3)
%   fprintf('l = annot_query(labelfile, annotfile, out)\n');
%   return;
% end

% delete existing output file
system(sprintf('rm -f %s', out));

% open output file
fid=fopen(out, 'a');

% read label
v_l=read_label_new(labelfile); % Freesurfer's read_label.m was adapted to accept the filepath as argument

% read annotation
[v,l,c]=read_annotation(annotfile,0);

% 0-based -> 1-based indices
v_l=v_l(:,1)+1;
idx_l=zeros(length(v),1);
idx_l(v_l)=1;

% cycle through anatomical labels
j=0;
for i=1:c.numEntries
  struct_id=c.table(i,5);
  idx_s=l==struct_id;
  idx=idx_l & idx_s;
  prop(i)=sum(idx)/sum(idx_l);
  if prop(i) > 0
    j=j+1;     
    lfiles{j}=labelfile;
    props(j)=prop(i);
    annots{j}=c.struct_names{i};
  
  end
end

% sort (highest percentage first)
[props, idx]=sort(props, 'descend');
lfiles=lfiles(idx);
annots=annots(idx);

% output
for i=1:j
    fprintf(fid,'%s : %s : %5.1f %%\n', lfiles{i}, annots{i}, props(i)*100);
    disp(sprintf('%s : %s : %5.1f %%\n', lfiles{i}, annots{i}, props(i)*100));
end
fprintf(fid,'%s : undefined : %5.1f %%\n', labelfile, 100-length(v_l)/sum(idx_l)*100);
disp(sprintf('%s : undefined : %5.1f %%\n', labelfile, 100-length(v_l)/sum(idx_l)*100));

% close output file
fclose(fid);
