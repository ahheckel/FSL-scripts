% Written by Andreas Heckel
% University of Heidelberg
% heckelandreas@googlemail.com
% https://github.com/ahheckel
% 02/20/2014

RSN_idx=1:14;
CSF_idx=15;
GM_idx=16;
WM_idx=17;
mask='./mask';
melodic_IC='./melodic_IC.nii.gz';
melodic_mix='./melodic_mix';
movpar='./movpar';
template='/usr/share/fsl/5.0/data/standard/rsn14_2mm.nii.gz';
funcIN='../test';
funcOut='../filtered_func_data_ICAdn';

system(sprintf('fslcc -m %s %s %s > /tmp/cc', mask, template, melodic_IC))
[a,b]=system(sprintf('fslnvols %s',melodic_IC))
nvols=str2num(b);

table=load('/tmp/cc');
mix=load(melodic_mix);
mc=load(movpar);
RR=table(:,3).^2;
ic=table(:,2);

RSN=[];
CSF=[];
WM=[];
noGM=[];
motion=[];

for i=1:nvols
    idx=(ic==i);
    if max(RR(idx))>0.02
        RSN=[RSN, i];
    end
end
            
for i=CSF_idx
    idx=(ic==i);
    if max(RR(idx))>0.05
        CSF=[CSF, i];
    end
end
    
for i=WM_idx
    idx=(ic==i);
    if max(RR(idx))>0.02
        WM=[WM, i];
    end
end

 for i=GM_idx
    idx=(ic==i);
    if min(RR(idx))<0.001
        noGM=[noGM, i];
    end
 end
 
 for i=1:nvols
     for j=1:length(size(mc,2))
         [r,p]=corr(mc(:,j),mix(:,i))
         if p<0.01
             motion=[motion, i];
             break
         end
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
     elseif sum(motion(motion==i)) > 0
         bad=[bad,i];
     else
         good=[good,i];
     end
 end
 
 disp('CSF:')
 disp(CSF)
 disp('noGM:')
 disp(noGM)
 disp('WM:')
 disp(WM)
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
 
