function fslcc
c=load('/tmp/fslcc_out');
tmpl_idx=c(:,2);
ic_idx=c(:,1);
vals=c(:,3);
cols=20;
rows=14;
X=zeros(rows,cols);

fid1=fopen('/tmp/rsn_labels');
d=textscan(fid1, '%s');
fclose(fid1);

for i=1:rows
    x=X(i,:);
    x(ic_idx(tmpl_idx==i))=vals(tmpl_idx==i);
    X(i,:)=x;
end

s='';
s2='';
for i=1:cols
   s=[s '%.2f '];
   s2=[s2 '%i '];
end

maxrow=max(X');
max_idx=0;
for i=1:rows
  foundmax=find(X(i,:)==maxrow(i),1);
  if (maxrow(i)==0)
      foundmax=NaN;
  end
  max_idx(i)=foundmax;
end

maxcol=max(X);
maxcol_idx=0;
for i=1:cols
  foundmax=find(X(:,i)==maxcol(i),1);
  if (maxcol(i)==0)
      foundmax=NaN;
  end
  maxcol_idx(i)=foundmax;
end

fid2=fopen('loop.txt', 'wt');

%display ICs sorted by r
[IC_r, IC_r_idx]=sort(maxcol);
IC_r2=IC_r.*IC_r;
maxcol_idx_s=maxcol_idx(IC_r_idx);
fprintf(fid2, ['%s %s %s %s\n'], 'IC', 'T', 'r', 'r^2');
for i=1:cols
   fprintf(fid2, ['%i %i %.2f %.2f \n'], IC_r_idx(i) , maxcol_idx_s(i), IC_r(i), IC_r2(i));
end
fprintf(fid2, ['\n']);

# display matrix
fprintf(fid2, ['%s %s ' s2 '%s %s %s\n'], '_', 'IC', 1:cols, 'r', 'r^2', 'ICmax');
for i=1:rows    
  fprintf(fid2, ['%i %s ' s '%.2f %.2f %i\n' ], i, d{1}{i}, X(i,:), maxrow(i), maxrow(i)^2, max_idx(i));
end
fprintf(fid2, ['%s %s ' s '%s %s %s \n' ],  '_', 'r', maxcol, '_','_','_');
fprintf(fid2, ['%s %s ' s '%s %s %s \n' ],  '_', 'r^2', maxcol.*maxcol, '_','_','_');
fprintf(fid2, ['%s %s ' s2 '%s %s %s \n' ], '_', 'ICmax', maxcol_idx, '_','_','_');

fclose(fid2);
