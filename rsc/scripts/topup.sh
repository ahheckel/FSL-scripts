#!/bin/bash

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}

function minmaxavg() # NB: min / max values are clamped to whole numbers
{
  awk 'NR == 1 { max=$1; min=$1; sum=0 }
  { if ($1>max) max=$1; if ($1<min) min=$1; sum+=$1;}
  END {printf "%d:%d:%f\n", min, max, sum/NR}'
}

function getMin() # finds minimum in column
{
  minmaxavg | cut -d ":" -f 1 
}

function subjsess() # remove '.' replacement in filename if no multiple sessions
{
  echo "${subj}${sess}" | sed  's/'$subj'\./'$subj'/'
}

function average()
{  
  awk '
  FNR==NR {
  for(i=1; i<=NF; i++)
  _[FNR,i]=$i
  next
  }
  {
  for(i=1; i<=NF; i++)
  printf("%.7f%s", ($i+_[FNR,i])/2, (i==NF) ? "\n" : FS);
  }' $1 $2
}

function getIdx() 
{
  local i=0;
  local vals=`cat $1` ; local val=""
  local target=$2

  for val in $vals ; do
    if test $val -eq $target ; then
      echo "$i"
    fi
    i=$[$i+1]
  done
}

function concat_bvecs()
{
 local file_pttrn=$1
 local dest=$2
 local concat0=""
 local concat1=""
 local concat2=""
 local bvec_txt=""
 local bvecs0=""
 local bvecs1=""
 local bvecs2=""

 for bvec_txt in `ls $file_pttrn` ; do
  echo "  `basename $bvec_txt`"  
	bvecs0=`sed -n 1p $bvec_txt`
	bvecs1=`sed -n 2p $bvec_txt`
	bvecs2=`sed -n 3p $bvec_txt`
	concat0=$concat0" "$bvecs0
	concat1=$concat1" "$bvecs1
	concat2=$concat2" "$bvecs2
 done 

 echo $concat0 > ${dest}
 echo $concat1 >> ${dest}
 echo $concat2 >> ${dest}
  
 wc ${dest}
}

function concat_bvals()
{
  local file_pttrn=$1
  local dest=$2
  local bval_txt=""
  local bvals=""
  local concat=""
  
  for bval_txt in `ls ${file_pttrn}` ; do
  echo "  `basename $bval_txt`"
	bvals=`cat $bval_txt`
	concat=$concat" "$bvals
  done  

  echo $concat > ${dest}
  wc ${dest}
}

function isClusterBusy() 
{ 
  if [ "x$SGE_ROOT" = "x" ] ; then echo "0"; return; fi # is cluster environment present ?
  
  # does qstat work ?
  qstat &>/dev/null
  if [ $? != 0 ] ; then 
    read -p "ERROR : qstat failed. Is Network available ? Abort with Control-C." >&2
    echo "1"
    return
  fi
  
  local user=`whoami | cut -c 1-10`
  local n_total=`qstat | grep $user | wc -l`
  local n_dr=`qstat | grep $user| awk '{print $5}' | grep dr | wc -l`
  local n_dt=`qstat | grep $user| awk '{print $5}' | grep dt | wc -l` 
  echo "$n_total - $n_dr - $n_dt" | bc -l # ignore zombie jobs
}

function waitIfBusy() 
{
  if [ `isClusterBusy` -gt 0 ] ; then
    echo -n "waiting..."
    while [ `isClusterBusy` -gt 0 ] ; do echo -n '.' ; sleep 30 ; done
    echo "done."
  fi
}

function countVols()
{
  local file_pattern=$1
  local summand0=0
  local summand1=0
  local n_total=0
  local file=""
  
  if [ `ls $file_pattern | wc -l` -eq 0 ] ; then echo "countVols(): ERROR: <$file_pattern> not found - exiting..." >&2 ; exit 1 ; fi

  for file in `ls $file_pattern` ; do
    summand1=`fslinfo  $file | grep ^dim4 | awk '{print $2}'`
    n_total=`echo "$summand0 + $summand1" | bc`
    summand0=$n_total;
  done
  echo "$n_total"
}


Usage() {
    echo ""
    echo "Usage: `basename $0` <out-dir> <dwi-plus> <dwi-minus> <TotalReadoutTime(s)> <USE-EC> [<dof> <costfunction>]"
    echo ""
    exit 1
}

[ "$4" = "" ] && Usage
outdir="$1"
pttrn_diffsplus="$2"
pttrn_diffsminus="$3"
TROT_topup=$4         # total readout time in seconds (EES_diff * (PhaseEncodingSteps - 1), i.e. 0.25 * 119 / 1000)
TOPUP_USE_EC=$5
if [ $TOPUP_USE_EC -eq 1 ] ; then
  TOPUP_EC_DOF=$6 # degrees of freedom used by eddy-correction
  TOPUP_EC_COST=$7  # cost-function used by eddy-correction
fi
TOPUP_USE_NATIVE=1

pttrn_bvalsplus=`remove_ext $pttrn_diffsplus`_bvals
pttrn_bvalsminus=`remove_ext $pttrn_diffsminus`_bvals
pttrn_bvecsplus=`remove_ext $pttrn_diffsplus`_bvecs
pttrn_bvecsminus=`remove_ext $pttrn_diffsminus`_bvecs

# create bval/bvec dummy files
if [ ! -f $pttrn_bvalsplus -a ! -f $pttrn_bvalsminus -a ! -f $pttrn_bvecsplus -a ! -f $pttrn_bvecsminus ] ; then
  $(dirname $0)/dummy_bvalbvec.sh $pttrn_diffsplus 4
  $(dirname $0)/dummy_bvalbvec.sh $pttrn_diffsminus 4
fi

mkdir -p $outdir
echo $outdir > .subjects
echo "." > $outdir/.sessions_struc
logdir=$outdir/logs ; mkdir -p $logdir
scriptdir=$(dirname $0)
tmpltdir=$(dirname $scriptdir)/templates

TOPUP_STG1=1
TOPUP_STG2=1
TOPUP_STG3=1               
TOPUP_STG4=1               
TOPUP_STG5=1               
TOPUP_STG6=1   

  
echo "`basename $0`: starting TOPUP..."
echo ""

# TOPUP prepare
if [ $TOPUP_STG1 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG1 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
    
      ## check if we have acquisition parameters
      #defineDWIparams config_acqparams_dwi $subj $sess
    
      if [ "x$pttrn_diffsplus" = "x" -o "x$pttrn_diffsminus" = "x" -o "x$pttrn_bvalsplus" = "x" -o "x$pttrn_bvalsminus" = "x" -o "x$pttrn_bvecsplus" = "x" -o "x$pttrn_bvecsminus" = "x" ] ; then
        echo "TOPUP : $outdir : ERROR : file search pattern for blipUp/blipDown DWIs not set..."
        continue
      fi
      
      fldr=${subj}/${sess}
      mkdir -p $fldr
      
      # display info
      echo "TOPUP : $outdir : preparing TOPUP... "
      
      # are the +- diffusion files in equal number ?
      n_plus=`ls $pttrn_diffsplus | wc -l`
      n_minus=`ls $pttrn_diffsminus | wc -l`
      if [ ! $n_plus -eq $n_minus ] ; then 
        echo "TOPUP : $outdir : ERROR : number of +blips diff. files ($n_plus) != number of -blips diff. files ($n_minus) - continuing loop..."
        continue
      elif [ $n_plus -eq 0 -a $n_minus -eq 0 ] ; then
        echo "TOPUP : $outdir : ERROR : no blip-up/down diffusion files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
                        
      # count +/- bvec/bval-files
      ls $pttrn_bvecsplus > $fldr/bvec+.files
      ls $pttrn_bvecsminus > $fldr/bvec-.files
      cat $fldr/bvec-.files $fldr/bvec+.files > $fldr/bvec.files
      ls $pttrn_bvalsplus > $fldr/bval+.files
      ls $pttrn_bvalsminus > $fldr/bval-.files
      cat $fldr/bval-.files $fldr/bval+.files > $fldr/bval.files
      n_vec_plus=`cat $fldr/bvec+.files | wc -l`
      n_vec_minus=`cat $fldr/bvec-.files | wc -l`
      n_val_plus=`cat $fldr/bval+.files | wc -l`
      n_val_minus=`cat $fldr/bval-.files | wc -l`
      
      #  are the +/- bvec-files equal in number ?
      if [ ! $n_vec_plus -eq $n_vec_minus ] ; then 
        echo "TOPUP : $outdir : ERROR : number of +blips bvec-files ($n_vec_plus) != number of -blips bvec-files ($n_vec_minus) - continuing loop..."
        continue
      elif [ $n_vec_plus -eq 0 -a $n_vec_minus -eq 0 ] ; then
        echo "TOPUP : $outdir : ERROR : no blip-up/down bvec-files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
      
      #  are the +/- bval-files equal in number ?
      if [ ! $n_val_plus -eq $n_val_minus ] ; then 
        echo "TOPUP : $outdir : ERROR : number of +blips bval-files ($n_val_plus) != number of -blips bval-files ($n_val_minus) - continuing loop..."
        continue
      elif [ $n_val_plus -eq 0 -a $n_val_minus -eq 0 ] ; then
        echo "TOPUP : $outdir : ERROR : no blip-up/down bval-files found for TOPUP (+/- must be part of the filename) - continuing loop..."
        continue
      fi
      
      # concatenate +bvecs and -bvecs
      concat_bvals "$pttrn_bvalsminus" $fldr/bvalsminus_concat.txt
      concat_bvals "$pttrn_bvalsplus" $fldr/bvalsplus_concat.txt 
      concat_bvecs "$pttrn_bvecsminus" $fldr/bvecsminus_concat.txt
      concat_bvecs "$pttrn_bvecsplus" $fldr/bvecsplus_concat.txt 

      nbvalsplus=$(wc -w $fldr/bvalsplus_concat.txt | cut -d " " -f 1)
      nbvalsminus=$(wc -w $fldr/bvalsminus_concat.txt | cut -d " " -f 1)
      nbvecsplus=$(wc -w $fldr/bvecsplus_concat.txt | cut -d " " -f 1)
      nbvecsminus=$(wc -w $fldr/bvecsplus_concat.txt | cut -d " " -f 1)      
     
      # check number of entries in concatenated bvals/bvecs files
      n_entries=`countVols "$pttrn_diffsplus"` 
      if [ $nbvalsplus = $nbvalsminus -a $nbvalsplus = $n_entries -a $nbvecsplus = `echo "3*$n_entries" | bc` -a $nbvecsplus = $nbvecsminus ] ; then
        echo "TOPUP : $outdir : number of entries in bvals- and bvecs files consistent ($n_entries entries)."
      else
        echo "TOPUP : $outdir : ERROR : number of entries in bvals- and bvecs files NOT consistent - continuing loop..."
        echo "(diffs+: $n_entries ; bvals+: $nbvalsplus ; bvals-: $nbvalsminus ; bvecs+: $nbvecsplus /3 ; bvecs-: $nbvecsminus /3)"
        continue
      fi
      
      # check if +/- bval entries are the same
      i=1
      for bval in `cat $fldr/bvalsplus_concat.txt` ; do
        if [ $bval != $(cat $fldr/bvalsminus_concat.txt | cut -d " " -f $i)  ] ; then 
          echo "TOPUP : $outdir : ERROR : +bval entries do not match -bval entries (they should have the same values !) - exiting..."
          exit
        fi        
        i=$[$i+1]
      done

      # creating index file for TOPUP
      echo "TOPUP : $outdir : creating index file for TOPUP..."      
      rm -f $fldr/$(subjsess)_acqparam.txt ; rm -f $fldr/$(subjsess)_acqparam_inv.txt ; rm -f $fldr/diff.files # clean-up previous runs...
      
      diffsminus=`ls ${pttrn_diffsminus}`
      for file in $diffsminus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "0 -1 0 $TROT_topup" >> $fldr/$(subjsess)_acqparam.txt
          echo "0 1 0 $TROT_topup" >> $fldr/$(subjsess)_acqparam_inv.txt
        done
      done
      
      diffsplus=`ls ${pttrn_diffsplus}`
      for file in $diffsplus ; do
        nvol=`fslinfo $file | grep ^dim4 | awk '{print $2}'`
        echo "$file n:${nvol}" | tee -a $fldr/diff.files
        for i in `seq 1 $nvol`; do
          echo "0 1 0 $TROT_topup" >> $fldr/$(subjsess)_acqparam.txt
          echo "0 -1 0 $TROT_topup" >> $fldr/$(subjsess)_acqparam_inv.txt
        done
      done
            
      # merging diffusion images for TOPUP    
      echo "TOPUP : $outdir : merging diffs... "
      fsl_sub -l $logdir -N topup_fslmerge_$(subjsess) fslmerge -t $fldr/diffs_merged $(cat $fldr/diff.files | cut -d " " -f 1)
    done
  done
  
  waitIfBusy
  
  # perform eddy-correction, if applicable
  if [ $TOPUP_USE_EC -eq 1 ] ; then
    for subj in `cat .subjects` ; do
      for sess in `cat ${subj}/.sessions_struc` ; do
        fldr=${subj}/${sess}
        
        # cleanup previous runs...
        rm -f $fldr/ec_diffs_merged_???_*.nii.gz # removing temporary files from prev. run
        if [ ! -z "$(ls $fldr/ec_diffs_merged_???.ecclog 2>/dev/null)" ] ; then    
          echo "TOPUP : $outdir : WARNING : eddy_correct logfile(s) from a previous run detected - deleting..."
          rm $fldr/ec_diffs_merged_???.ecclog # (!)
        fi
        # eddy-correct each run...
        for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # note: don't use seq -w (bash compatibility issues!) (!)
          dwifile=$(cat $fldr/diff.files | sed -n ${i}p | cut -d " " -f 1)
          bvalfile=$(cat $fldr/bval.files | sed -n ${i}p)
          
          # get B0 index          
          b0img=`getB0Index $bvalfile $fldr/ec_ref_${i}.idx | cut -d " " -f 1` ; min=`getB0Index $bvalfile $fldr/ec_ref_${i}.idx | cut -d " " -f 2` 
          
          # create a task file for fsl_sub, which is needed to avoid accumulations when SGE does a re-run on error
          echo "rm -f $fldr/ec_diffs_merged_${i}*.nii.gz ; \
                rm -f $fldr/ec_diffs_merged_${i}.ecclog ; \
                $scriptdir/eddy_correct.sh $dwifile $fldr/ec_diffs_merged_${i} $b0img $TOPUP_EC_DOF $TOPUP_EC_COST trilinear" > $fldr/topup_ec_${i}.cmd
          
          # eddy-correct
          echo "TOPUP : $outdir : eddy_correction of '$dwifile' (ec_diffs_merged_${i}) is using volume no. $b0img as B0 (val:${min})..."
          fsl_sub -l $logdir -N topup_eddy_correct_$(subjsess) -t $fldr/topup_ec_${i}.cmd
        done        
      done
    done
    
    waitIfBusy    
    
    # plot ecclogs...
    for subj in `cat .subjects` ; do
      for sess in `cat ${subj}/.sessions_struc` ; do
        fldr=${subj}/${sess}
        cd $fldr
        for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # note: don't use seq -w (bash compatibility issues!) (!)
          echo "TOPUP : $outdir : plotting ec_diffs_merged_${i}.ecclog..."
          eddy_correct_plot ec_diffs_merged_${i}.ecclog $(subjsess)-${i}
          # horzcat
          pngappend ec_disp.png + ec_rot.png + ec_trans.png ec_${i}.png
          # accumulate
          if [ $i -gt 1 ] ; then
            pngappend ec_plot.png - ec_${i}.png ec_plot.png
          else
            cp ec_${i}.png ec_plot.png
          fi
          # cleanup
          rm  ec_disp.png ec_rot.png ec_trans.png ec_${i}.png
        done
        cd $subj
      done
    done
      
  fi
fi

waitIfBusy

# TOPUP low-B images: create index and extract
if [ $TOPUP_STG2 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG2 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : $outdir : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # display info
      echo "TOPUP : $outdir : concatenate bvals... "
      echo "`cat $fldr/bvalsminus_concat.txt`" "`cat $fldr/bvalsplus_concat.txt`" > $fldr/bvals_concat.txt
       
      # get B0 index
      min=`row2col $fldr/bvals_concat.txt | getMin` # find minimum value (usually representing the "B0" image)
      echo "TOPUP : $outdir : minimum b-value in merged diff. is $min"
      b0idces=`getIdx $fldr/bvals_concat.txt $min`
      echo $b0idces | row2col > $fldr/lowb.idx
      
      # creating index file for topup (only low-B images)
      echo "TOPUP : $outdir : creating index file for TOPUP (only low-B images)..."      
      rm -f $fldr/$(subjsess)_acqparam_lowb.txt ; rm -f $fldr/$(subjsess)_acqparam_lowb_inv.txt # clean-up previous runs...
      for b0idx in $b0idces ; do
        line=`echo "$b0idx + 1" | bc -l`
        cat $fldr/$(subjsess)_acqparam.txt | sed -n ${line}p >> $fldr/$(subjsess)_acqparam_lowb.txt
        cat $fldr/$(subjsess)_acqparam_inv.txt | sed -n ${line}p >> $fldr/$(subjsess)_acqparam_lowb_inv.txt
      done
          
      # creating index file for topup (only the first low-B image in each dwi file)
      echo "TOPUP : $outdir : creating index file for TOPUP (only the first low-B image in each dwi-file)..." 
      c=0 ; _nvol=0 ; nvol=0
      rm -f $fldr/$(subjsess)_acqparam_lowb_1st.txt ; rm -f $fldr/$(subjsess)_acqparam_lowb_1st_inv.txt # clean-up previous runs...
      for i in $(cat $fldr/bval.files) ; do
        _min=`row2col $i | getMin`
        _idx=`getIdx $i $_min` ;  _idx=$(echo $_idx | cut -d " " -f 1) ; _idx=$(echo "$_idx + 1" | bc -l)
        if [ $c -gt 0 ] ; then
          _nvol=$(cat $fldr/diff.files | sed -n ${c}p | cut -d ":" -f 2-) ;
        fi
        nvol=$(( $nvol + $_nvol ))
        _line=$(echo "$nvol + $_idx" | bc -l)
        
        cat $fldr/$(subjsess)_acqparam.txt | sed -n ${_line}p >> $fldr/$(subjsess)_acqparam_lowb_1st.txt
        cat $fldr/$(subjsess)_acqparam_inv.txt | sed -n ${_line}p >> $fldr/$(subjsess)_acqparam_lowb_1st_inv.txt
        c=$[$c+1]
      done   
      
      # extract B0 images
      lowbs=""
      for b0idx in $b0idces ; do    
        echo "TOPUP : $outdir : found B0 images in merged diff. at pos. $b0idx (val:${min}) - extracting..."
        lowb="$fldr/b${min}_`printf '%05i' $b0idx`"
        fsl_sub -l $logdir -N topup_fslroi_$(subjsess) fslroi $fldr/diffs_merged $lowb $b0idx 1
        lowbs=$lowbs" "$lowb
      done
      
      # save filenames to text file
      echo "$lowbs" > $fldr/lowb.files; lowbs=""
      
      # wait here to prevent overload...
      waitIfBusy
    done
  done
fi

waitIfBusy

# TOPUP merge B0 images
if [ $TOPUP_STG3 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG3 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : $outdir : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # merge B0 images
      echo "TOPUP : $outdir : merging low-B images..."
      fsl_sub -l $logdir -N topup_fslmerge_$(subjsess) fslmerge -t $fldr/$(subjsess)_lowb_merged $(cat $fldr/lowb.files)
      
    done
  done
fi

waitIfBusy

# TOPUP execute TOPUP
if [ $TOPUP_STG4 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG4 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : $outdir : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # execute TOPUP
      echo "TOPUP : $outdir : executing TOPUP on merged low-b volumes..."
      echo "fsl_sub -l $logdir -N topup_topup_$(subjsess) topup -v --imain=$fldr/$(subjsess)_lowb_merged --datain=$fldr/$(subjsess)_acqparam_lowb.txt --config=b02b0.cnf --out=$fldr/$(subjsess)_field_lowb" > $fldr/topup.cmd
      . $fldr/topup.cmd
     
    done
  done
fi

waitIfBusy

# TOPUP apply warp
if [ $TOPUP_STG5 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG5 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      if [ ! -f $fldr/$(subjsess)_acqparam.txt ] ; then echo "TOPUP : $outdir : ERROR : parameter file $fldr/$(subjsess)_acqparam.txt not found - continuing loop..." ; continue ; fi
      
      # generate commando without eddy-correction
      nplus=`ls $subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`

        blipdown=`ls $subj/$sess/$pttrn_diffsminus | sed -n ${i}p`
        blipup=`ls $subj/$sess/$pttrn_diffsplus | sed -n ${i}p`
        
        n=`printf %03i $i`
        echo "applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb_1st.txt --inindex=$i,$j --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr" >> $fldr/applytopup.cmd
      done
      
      # generate commando with eddy-correction
      nplus=`ls $subj/$sess/$pttrn_diffsplus | wc -l`      
      rm -f $fldr/applytopup_ec.cmd
      for i in `seq 1 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l`
        
        blipdown=$fldr/ec_diffs_merged_$(printf %03i $i)
        blipup=$fldr/ec_diffs_merged_$(printf %03i $j)
        
        n=`printf %03i $i`
        echo "applytopup --imain=$blipdown,$blipup --datain=$fldr/$(subjsess)_acqparam_lowb_1st.txt --inindex=$i,$j --topup=$fldr/$(subjsess)_field_lowb --method=lsr --out=$fldr/${n}_topup_corr_ec" >> $fldr/applytopup_ec.cmd
      done
    done
  done
  
  # execute...
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
  
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : $outdir : applying warps to native DWIs..."
        fsl_sub -l $logdir -N topup_applytopup_$(subjsess) -t $fldr/applytopup.cmd
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : $outdir : applying warps to eddy-corrected DWIs..."
        fsl_sub -l $logdir -N topup_applytopup_ec_$(subjsess) -t $fldr/applytopup_ec.cmd
      fi
    done
  done
       
  waitIfBusy
      
  # merge corrected files and remove negative values
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      # merge corrected files
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then
        echo "TOPUP : $outdir : merging topup-corrected DWIs..."
        fslmerge -t $fldr/$(subjsess)_topup_corr_merged $(imglob $fldr/*_topup_corr)
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : $outdir : merging topup-corrected & eddy-corrected DWIs..."
        fslmerge -t $fldr/$(subjsess)_topup_corr_ec_merged $(imglob $fldr/*_topup_corr_ec)
      fi
      
      # remove negative values
      echo "TOPUP : $outdir : zeroing negative values in topup-corrected DWIs..."
      if [ -f $fldr/$(subjsess)_topup_corr_merged.nii.gz ] ; then fsl_sub -l $logdir -N topup_noneg_$(subjsess) fslmaths $fldr/$(subjsess)_topup_corr_merged -thr 0 $fldr/$(subjsess)_topup_corr_merged ; fi
      if [ -f $fldr/$(subjsess)_topup_corr_ec_merged.nii.gz ] ; then fsl_sub -l $logdir -N topup_noneg_ec_$(subjsess) fslmaths $fldr/$(subjsess)_topup_corr_ec_merged -thr 0 $fldr/$(subjsess)_topup_corr_ec_merged ; fi
    done
  done    
fi

waitIfBusy

# TOPUP estimate tensor model
if [ $TOPUP_STG6 -eq 1 ] ; then
  echo "----- BEGIN TOPUP_STG6 -----"
  for subj in `cat .subjects` ; do
    for sess in `cat ${subj}/.sessions_struc` ; do
      fldr=${subj}/${sess}
      
      # get info for current subject
      f=0.2 # (!)

      # bet, if necessary
      if [ $f = "mod" ] ; then
        if [ ! -f $fldr/nodif_brain_${f}.nii.gz  -o ! -f $fldr/nodif_brain_${f}_mask.nii.gz ] ; then   
          echo "TOPUP: $outdir : externally modified volume (nodif_brain_${f}) & mask (nodif_brain_${f}_mask) not found - exiting..." ; exit
        fi
      else      
        echo "TOPUP : $outdir : betting B0 image with fi=${f} - extracting B0..."
        if [ ! -f $fldr/lowb.idx ] ; then echo "TOPUP : $outdir : ERROR : low-b index file '$fldr/lowb.idx' not found - continuing loop..." ; continue ; fi
        fslroi $fldr/diffs_merged $fldr/nodif $(sed -n 1p $fldr/lowb.idx) 1
        echo "TOPUP : $outdir : ...and betting B0..."
        bet $fldr/nodif $fldr/nodif_brain_${f} -m -f $f         
      fi 
      ln -sf nodif_brain_${f}.nii.gz $fldr/nodif_brain.nii.gz
      ln -sf nodif_brain_${f}_mask.nii.gz $fldr/nodif_brain_mask.nii.gz      
    
      # averaging +/- bvecs & bvals...
      # NOTE: bvecs are averaged further below (following rotation)
      average $fldr/bvalsminus_concat.txt $fldr/bvalsplus_concat.txt > $fldr/avg_bvals.txt
      
      # rotate bvecs to compensate for eddy-correction, if applicable
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        if [ -z "$(ls $fldr/ec_diffs_merged_???.ecclog 2>/dev/null)" ] ; then 
          echo "TOPUP : $outdir : ERROR : *.ecclog file(s) not found, but needed to rotate b-vectors -> skipping this part..." 
        
        else 
          for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do
            bvecfile=`sed -n ${i}p $fldr/bvec.files`
            echo "TOPUP : $outdir : rotating '$bvecfile' according to 'ec_diffs_merged_${i}.ecclog'"
            xfmrot $fldr/ec_diffs_merged_${i}.ecclog $bvecfile $fldr/bvecs_ec_${i}.rot
          done
        fi
      fi
      
      # rotate bvecs to compensate for TOPUP 6 parameter rigid-body correction using OCTAVE (for each run)
      for i in `seq -f %03g 001 $(cat $fldr/diff.files | wc -l)` ; do # for each run do...        
        # copy OCTAVE template
        cp $tmpltdir/template_makeXfmMatrix.m $fldr/makeXfmMatrix_${i}.m
        
        # define vars
        rots=`sed -n ${i}p $fldr/$(subjsess)_field_lowb_movpar.txt | awk '{print $4"  "$5"  "$6}'` # cut -d " " -f 7-11` # last three entries are rotations in radians 
        nscans=`sed -n ${i}p $fldr/diff.files | cut -d : -f 2` # number of scans in run
        fname_mat=$fldr/topup_diffs_merged_${i}.mat # filename with n 4x4 affine matrices
        
        # do run-specific substitutions in OCTAVE template
        sed -i "s|function M = .*|function M = makeXfmMatrix_${i}|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|R=.*|R=[$rots]|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|repeat=.*|repeat=$nscans|g" $fldr/makeXfmMatrix_${i}.m
        sed -i "s|filename=.*|filename='$fname_mat'|g" $fldr/makeXfmMatrix_${i}.m
        
        # change directory and unset error flag because of strange OCTAVE behavior and unclear error 'error: matrix cannot be indexed with .' - but seems to work anyhow
        cd $fldr
          set +e # unset exit on error bc. octave always throws an error (?)
          echo "TOPUP : $outdir : create rotation matrices '$(basename $fname_mat)' ($nscans entries) for 6-parameter TOPUP motion correction (angles: $rots)..."
          echo "NOTE: Octave may throw an error here for reasons unknown."
          octave -q --eval makeXfmMatrix_${i}.m >& /dev/null
          set -e
        cd $subj
        
        # check the created rotation matrix
        head -n8 $fname_mat > $fldr/check.mat
        echo "TOPUP : $outdir : CHECK rotation angles - topup input: $(printf ' %0.6f' $rots)"
        echo "TOPUP : $outdir : CHECK rotation angles - avscale out: $(avscale --allparams $fldr/check.mat | grep "Rotation Angles" | cut -d '=' -f2)"
        rm $fldr/check.mat
        
        # apply the rotation matrix to b-vector file
        if [ $TOPUP_USE_NATIVE -eq 1 ] ; then 
          bvecfile=`sed -n ${i}p $fldr/bvec.files`
          echo "TOPUP : $outdir : apply rotation matrices '$(basename $fname_mat)' to '`basename $bvecfile`' -> 'bvecs_topup_${i}.rot'"
          xfmrot $fname_mat $bvecfile $fldr/bvecs_topup_${i}.rot
        fi        
        if [ $TOPUP_USE_EC -eq 1 ] ; then
          bvecfile=$fldr/bvecs_ec_${i}.rot
          echo "TOPUP : $outdir : apply rotation matrices '$(basename $fname_mat)' to '`basename $bvecfile`' -> 'bvecs_topup_ec_${i}.rot'"
          xfmrot $fname_mat $bvecfile $fldr/bvecs_topup_ec_${i}.rot
        fi
      done
      
      # average rotated bvecs
      nplus=`cat $fldr/bvec+.files | wc -l`
      for i in `seq -f %03g 001 $nplus` ; do
        j=`echo "$i + $nplus" | bc -l` ; j=`printf %03i $j`
        if [ $TOPUP_USE_NATIVE -eq 1 ] ; then 
          echo "TOPUP : $outdir : averaging rotated blip+/blip- b-vectors (no eddy-correction)..."
          average $fldr/bvecs_topup_${i}.rot $fldr/bvecs_topup_${j}.rot > $fldr/avg_bvecs_topup_${i}.rot
        fi
        if [ $TOPUP_USE_EC -eq 1 ] ; then
          echo "TOPUP : $outdir : averaging rotated blip+/blip- b-vectors (incl. eddy-correction)..."
          average $fldr/bvecs_topup_ec_${i}.rot $fldr/bvecs_topup_ec_${j}.rot > $fldr/avg_bvecs_topup_ec_${i}.rot
        fi
      done
      
      # concatenate averaged and rotated bvecs
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then      
       echo "TOPUP : $outdir : concatenate averaged and rotated b-vectors (no eddy-correction)..."
       concat_bvecs "$fldr/avg_bvecs_topup_???.rot" $fldr/avg_bvecs_topup.rot
      fi      
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : $outdir : concatenate averaged and rotated b-vectors (incl. eddy-correction)..."
        concat_bvecs "$fldr/avg_bvecs_topup_ec_???.rot" $fldr/avg_bvecs_topup_ec.rot
      fi
      
      # display info
      echo "TOPUP : $outdir : dtifit is estimating tensor model using nodif_brain_${f}_mask..."
      
      # estimate tensor model (rotated bvecs)
      if [ $TOPUP_USE_NATIVE -eq 1 ] ; then           
        echo "TOPUP : $outdir : dtifit is estimating tensor model with rotated b-vectors (no eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_noec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_merged -m $fldr/nodif_brain_mask -r $fldr/avg_bvecs_topup.rot -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_noec_bvecrot
      fi
      if [ $TOPUP_USE_EC -eq 1 ] ; then
        echo "TOPUP : $outdir : dtifit is estimating tensor model with rotated b-vectors (incl. eddy-correction)..."
        fsl_sub -l $logdir -N topup_dtifit_ec_bvecrot_$(subjsess) dtifit -k $fldr/$(subjsess)_topup_corr_ec_merged -m $fldr/nodif_brain_mask -r $fldr/avg_bvecs_topup_ec.rot  -b $fldr/avg_bvals.txt  -o $fldr/$(subjsess)_dti_topup_ec_bvecrot
      fi
    done
  done
fi
      
#######################
# ----- END TOPUP -----
#######################

echo "" 
echo "`basename $0`: done."
