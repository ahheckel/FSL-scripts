
logfile="$1"
sm_krnl=$2

smoothsigma=$(echo "scale=10; $sm_krnl / 2.355" | bc -l)

l0=$[$(cat $logfile | grep -n " \-p 2 -p 98" | cut -d : -f 1) +1]
l1=$[$(cat $logfile | grep -n " \-k mask -p 50" | cut -d : -f 1) +1]

p2=$(sed -n ${l0}p $logfile | cut -d ' ' -f 1)
median=$(sed -n ${l1}p $logfile)

echo "line $l0 : p2 is $p2"
echo "line $l1 : median is $median"
susan_int=$(echo "($median - $p2) * 0.75" | bc -l)
echo "susan prefiltered_func_data_thresh $susan_int $smoothsigma 3 1 1 mean_func $susan_int prefiltered_func_data_smooth"
