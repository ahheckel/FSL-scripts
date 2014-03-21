function r=regress_out(indata, confounds)

%r=regress_out(indata, confounds)

data=indata - repmat(mean(indata,1), [size(indata,1),1]);
conf=confounds - repmat(mean(confounds,1), [size(confounds,1),1]);
data_clean=zeros(size(data));
for i=1:size(data,2)
    beta=regress(data(:,i), conf);
    data_clean(:,i)=data(:,i) - conf*beta + mean(indata(:,i));
end
r=data_clean;
