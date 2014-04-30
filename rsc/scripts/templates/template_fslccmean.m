function fslcc
c=load('/tmp/fslcc_out');
tmpl_idx=c(:,2);
ic_idx=c(:,1);
vals=c(:,3);
cols=20;
rows=14;
X=zeros(rows,cols);

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

max_mean=mean(maxrow);

fid2=fopen('loop.txt', 'wt');
fprintf(fid2, [ '%.4f \n' ],max_mean);
fclose(fid2);
