function f = annot_query(labelfile, annotfile, out)

% Written by Andreas Heckel
% University of Freiburg
% heckelandreas@googlemail.com
% https://github.com/ahheckel
% 05/18/2015

%labelfile='/home/andi/projects/a.label'
%annotfile='/usr/local/freesurfer/subjects/fsaverage/label/lh.aparc.a2009s.annot'
%out='a.txt';

if(nargin ~= 3)
  fprintf('l = annot_query(labelfile, annotfile, out)\n');
  return;
end

% delete existing output file
system(sprintf('rm -f %s', out));

% open output file
fid=fopen(out, 'a');

v_l=read_label_new(labelfile); % read_label_new was adapted to accept the file path as argument
[v,l,c]=read_annotation(annotfile,0);

% 0-based -> 1-based indices
v_l=v_l(:,1)+1;
idx_l=zeros(length(v),1);
idx_l(v_l)=1;

% cycle through anatomical labels
for i=1:c.numEntries
  struct_id=c.table(i,5);
  idx_s=l==struct_id;
  idx=idx_l & idx_s;
  prop(i)=sum(idx)/sum(idx_l);
  if prop(i) > 0
    disp(sprintf('%s : %s : %.1f\n', labelfile, c.struct_names{i}, prop(i)))
    fprintf(fid,'%s : %s : %.1f\n', labelfile, c.struct_names{i}, prop(i));
  end
end
disp(sprintf('%s : undefined : %.1f\n', labelfile, 1-length(v_l)/sum(idx_l)))
fprintf(fid,'%s : undefined : %.1f\n', labelfile, 1-length(v_l)/sum(idx_l));

% close output file
fclose(fid);
