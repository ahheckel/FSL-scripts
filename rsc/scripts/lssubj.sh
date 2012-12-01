#!/bin/bash
cd $1
find ./ -maxdepth 1 -mindepth 1 -type d \( ! -iname ".*" \) | cut -d / -f 2 | grep -v FS_ | sort
