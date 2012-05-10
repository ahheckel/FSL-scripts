#!/bin/bash

for i in warn error segfault segmentation rejected oops denied fail cannot critical panic usage ; do
    grep -i -R  $i $1 --color=auto
done



