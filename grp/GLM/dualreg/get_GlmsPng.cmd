files=`find ./ -name design.png | sort`
for i in $files ; do echo $i ; done
n=1
montage -tile 1x${n} -mode Concatenate $(find ./ -name design.png | sort) glm.png

