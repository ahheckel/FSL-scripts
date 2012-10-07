#!/bin/bash
#gksudo ifup eth0
user="$1"
if [ $user = "l" ] ; then user=kiralutz ; fi
if [ $user = "h" ] ; then user=heckelandreas ; fi
ssh -X "$user"@161.42.71.18

