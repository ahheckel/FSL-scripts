function f = annotquery_sig(sigfiles, annotfile, tval, out)

% Written by Andreas Heckel
% University of Freiburg
% heckelandreas@googlemail.com
% https://github.com/ahheckel
% 05/20/2015

% sigfiles=SIGFILES;
% annotfile=ANNOT;
% out=OUT;
% tval=TVAL;

%  sigfiles={'/home/andi/projects/biller/testsig.mgh','/home/andi/projects/biller/testsig.mgh'};
%  annotfile='/usr/local/freesurfer/subjects/fsaverage/label/lh.aparc.a2009s.annot';
%  out='test.txt';
%  tval=-1.5 ;

 
% if(nargin ~= 4)
%   fprintf('l = annotquery_sig(sigfiles, annotfile, val, out)\n');
%   return;
% end

% delete existing output file
system(sprintf('rm -f %s', out));

% open output file
fid=fopen(out, 'a');

% read annotation
[v,l,c]=read_annotation(annotfile,0);

% write headings
fprintf(fid,'input\t anat\t n_input/n_anat*100\t n_anat/n_input*100\t tval \t\n');

% for each sigfile...
for k=1:length(sigfiles)    
  sigfile=sigfiles{k};
  
  %read label 
  v_l=load_mgh(sigfile);

  % create index vector
  if sign(tval)>0
      idx_l=v_l>=tval;
  elseif sign(tval)<0
      idx_l=v_l<=tval;
  end    
      
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
      lfiles{j}=sigfile;
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
      fprintf(fid,'%s: %s: %5.1f %5.1f %6.2f\n', lfiles{i}, annots{i}, props(i)*100, propinvs(i)*100, tval);
  end
  fprintf(fid,'%s: undefined: %5.1f\n', sigfile, 100-sum(props)*100);
end

% display output
system(sprintf('cat %s', out));

% close output file
fclose(fid);
