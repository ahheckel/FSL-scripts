#!/bin/bash

for i in $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS ; do
  xterm -geometry 120x80  -bg black -fg green -sb -sl 5000 -e /bin/bash -c "tail -f $i" 
done
