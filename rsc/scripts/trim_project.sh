# Written by Andreas Heckel
# University of Heidelberg
# heckelandreas@googlemail.com
# https://github.com/ahheckel
# 04/25/2013

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

function getMax() # finds maximum in column
{
  minmaxavg | cut -d ":" -f 2 
}

function getAvg() # averages column
{
  minmaxavg | cut -d ":" -f 3
}

function row2col()
{
  local dat=`cat $1`
  local i=""
  for i in $dat ; do echo $i ; done
}


trap 'echo "$0 : An ERROR has occured." ; exit 1' ERR
set -e

Usage() {
    echo ""
    echo "Usage:       `basename $0` <root-dir> <pttrn> <textfile>"
    echo "Example:     `basename $0` ./data-dir  \*restingTE\* triminfo.txt"
    echo "triminfo.txt:"
    echo "              #ID      a       b       c       d"
    echo "              01       0       9       7       9"
    echo "              02       8       0       9       8"
    echo "              03       8       8       0       9"
    echo "              04       10      10      10      0"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage

# define input vars
rootdir="$1"
pttrn="$2"
txtin="$3"

# create working dir.
tmpdir=$(mktemp -d -t $(basename $0)_XXXXXXXXXX) # create unique dir. for temporary files

# define exit trap
trap "rm -f $tmpdir/* ; rmdir $tmpdir ; exit" EXIT

# additional vars
txtin_tmp=$tmpdir/txtin.txt
header_tmp=$tmpdir/header.txt

# remove blanks and text header
istext=1 ; iscomment=1
cat $txtin | sed '/^$/d' | grep -v ^[[:blank:]] > $txtin_tmp
for i in `seq 1 $(cat $txtin_tmp | wc -l)` ; do
  istext=$(sed -n ${i}p $txtin_tmp | grep "[[:alpha:]]" | wc -l)
  iscomment=$(sed -n ${i}p $txtin_tmp | grep ^# | wc -l)
  if [ $istext -eq 0 -a $iscomment -eq 0 ] ; then break ; fi
done
j=$[$i-1]
if [ $j -gt 0 ] ; then head -n${j} $txtin_tmp > $header_tmp ; else touch $header_tmp ; fi
tail -n+${i} $txtin_tmp > $tmpdir/_txtin.txt ; mv $tmpdir/_txtin.txt $txtin_tmp
#echo "`basename $0`: discarding ${j} header lines"
i="" ; j=""

# determine number of columns
n_col=$(awk '{print NF}' $txtin_tmp | sort -nu | head -n 1)

# determine maximum value
c=$(cat $txtin_tmp | awk '{for (i=2 ; i<NF; i++) printf $i " " ; print $NF}' | getMax)
max=$(echo $c | row2col | getMax)

# number of lines
nl=$(cat $txtin_tmp | wc -l)

# trimming
for l in `seq 1 $nl` ; do

  for c in `seq 1 $n_col` ; do
    entry=$(cat $txtin_tmp | sed -n ${l}p | awk -v c=${c} '{print $c}')
    n_sess=$(echo "$c - 1" | bc )
    sess=$(cat $header_tmp | awk -v c=${c} '{print $c}')
    input=""
    output=""
    if [ $c -eq 1 ] ; then
      subj=$entry ; 
      #echo "subj = $subj" ; 
    else 
      sess=$(cat $header_tmp | awk -v c=${c} '{print $c}') ;
      #echo $sess ;  
    fi
    if [ $c -ge 2 ] ; then 
      diff=$(echo "$max - $entry" | bc) ;
      input=$(ls $rootdir/$subj/${pttrn} | sed -n ${n_sess}p) ;
      output=$rootdir/$subj/$sess/bold_${n_sess}.nii.gz
      echo "trim4D.sh $input $entry,$diff $output"
    fi
  
  done
done

# cleanup
rm -f $txtin_tmp $header_tmp
