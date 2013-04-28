files=`find ./ -name design.png | sort`
n=`echo $files | wc -w`
n=`echo "$n / 2" | bc -l`
for i in $files ; do echo $i ; done

montage -tile 1x${n} -mode Concatenate $(find ./ -name design.png | sort) glm_all.png

