#/bin/bash

trap 'echo -e "\n********************\nTo cancel background job type \n kill $(cat ./log | grep Job | cut -d : -f 2)\n\nTo view logfile type \n tail -f log\n"********************' EXIT

nohup ./run_script.sh &> log &
tail -f log
