RSN_idx=1:14;
CSF_idx=15;
GM_idx=16;
WM_idx=17;
mask='./mask';
melodic_IC='./melodic_IC.nii.gz';
melodic_mix='./melodic_mix';
template='./rsn14_3mm.nii.gz';
funcIN='./filtered_func_data';
funcOut='./filtered_func_data_ICAdn';

system(sprintf('fslcc -m %s %s %s > /tmp/cc', mask, template, melodic_IC))
[a,b]=system('fslnvols %s',melodic_IC);
nvols=str2num(b);

table=load('/tmp/cc');
RR=table(:,3).^2;
ic=table(:,2);

RSN=[];
CSF=[];
WM=[];
noGM=[];

for i=1:nvols
    idx=ic(ic==i);
    if max(RR(idx))>0.02
        RSN=[RSN, i];
    end
end
            
for i=1:nvols
    idx=ic(ic==i);
    if max(RR(idx))>0.05
        CSF=[CSF, i];
    end
end
    
for i=1:nvols
    idx=ic(ic==i);
    if max(RR(idx))>0.02
        WM=[WM, i];
    end
end

 for i=1:nvols
    idx=ic(ic==i);
    if min(RR(idx))<0.001
        noGM=[noGM, i];
    end
 end
 
 good=[];
 bad=[];
 for i=1:nvols
     if sum(RSN(RSN==i)) > 0
         good=[good,i];
     elseif sum(CSF(CSF==i)) > 0
         bad=[bad,i];
     elseif sum(WM(WM==i)) > 0
         bad=[bad,i];         
     elseif sum(noGM(noGM==i)) > 0
         bad=[bad,i];
     else
         good=[good,i];
     end
 end
 
 disp('good:')
 disp(good)
 disp('bad:')
 disp(bad)
 
 bad_str='';
 for i=bad
     bad_str=[bad_str, ',', num2str(i)];
 end
 bad_str=bad_str(2:end);
 
 system(sprintf('fsl_regfilt -i %s -d %s -f %s -o %s',funcIN, melodic_mix, bad_str, funcOut))
 
 system('rm -f /tmp/cc')
 