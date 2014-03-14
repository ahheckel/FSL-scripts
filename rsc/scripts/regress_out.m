function r=regress_out(indata, confound)

%r=regress_out(indata, confound)

data=demean(indata,1);
conf=confound-mean(confound);
data_clean=zeros(size(data));
for i=1:size(data,2)
    beta=regress(data(:,i), conf);
    data_clean(:,i)=data(:,i) - conf*beta + mean(indata(:,i));
end
r=data_clean;
