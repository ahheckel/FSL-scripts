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
      foundmax=-1;
  end
  max_idx(i)=foundmax;
end

fid2=fopen('loop.txt', 'wt');
%disp(sprintf(['%s ' s2 '%s %s %s'], 'IC', 1:cols, 'r', 'r^2', 'ICmax'));
fprintf(fid2, ['%s ' s2 '%s %s %s\n'], 'IC', 1:cols, 'r', 'r^2', 'ICmax');
for i=1:rows    
  %disp(sprintf(['%s ' s '%.2f %.2f %i' ], d{1}{i}, X(i,:), maxrow(i), maxrow(i)^2, max_idx(i)))
  fprintf(fid2, ['%s ' s '%.2f %.2f %i\n' ], d{1}{i}, X(i,:), maxrow(i), maxrow(i)^2, max_idx(i));
end
fclose(fid2);    
