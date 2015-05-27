function f = annotquery_label(labelfiles, annotfile, out)

% Written by Andreas Heckel
% University of Freiburg
% heckelandreas@googlemail.com
% https://github.com/ahheckel
% 05/18/2015

% labelfiles=LABELS;
% annotfile=ANNOT;
% out=OUT;

% 
% if(nargin ~= 3)
%   fprintf('l = annotquery_label(labelfiles, annotfile, out)\n');
%   return;
% end

% delete existing output file
system(sprintf('rm -f %s', out));

% open output file
fid=fopen(out, 'a');

% read annotation
[v,l,c]=read_annotation(annotfile,0);

% write headings
fprintf(fid,'input\t anat\t n_input/n_anat*100\t n_anat/n_input*100\n');

% for each labelfile...
for k=1:length(labelfiles)    
    labelfile=labelfiles{k};
    
    % read label
    v_l=readlabel(labelfile); % Freesurfer's read_label.m was adapted by HKL to accept filepath as argument

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
      propinv(i)=sum(idx)/sum(idx_s);
      if prop(i) > 0
        j=j+1;     
        lfiles{j}=labelfile;
        props(j)=prop(i);
        propinvs(j)=propinv(i);
        annots{j}=c.struct_names{i};  
      end
    end

    % sort (highest percentage first)
    [props, idx]=sort(props, 'descend');
    propinvs=propinvs(idx);
    lfiles=lfiles(idx);
    annots=annots(idx);

    % output
    for i=1:j
        fprintf(fid,'%s: %s: %5.1f %5.1f\n', lfiles{i}, annots{i}, props(i)*100, propinvs(i)*100);        
    end
    fprintf(fid,'%s: undefined: %5.1f\n', lfiles{i}, 100-sum(props)*100);    
end

% display output
system(sprintf('cat %s', out));

% close output file
fclose(fid);

% EXIT;
end

function l = readlabel(lname)

l = [] ;
fname = sprintf('%s', lname) ;

fid = fopen(fname, 'r') ;
if(fid == -1)
  fprintf('ERROR: could not open %s\n',fname);
  return;
end

fgets(fid) ;

if(fid == -1)
  fprintf('ERROR: could not open %s\n',fname);
  return;
end

line = fgets(fid) ;
nv = sscanf(line, '%d') ;
l = fscanf(fid, '%d %f %f %f %f\n') ;
l = reshape(l, 5, nv) ;
l = l' ;

fclose(fid) ;
end