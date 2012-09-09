
#!/bin/bash
# overwrite FSL-scripts with new version

trap 'echo "$0 : An ERROR has occured."' ERR

set -e

Usage() {
    echo "Updates /FSL-scripts."
    echo "Usage: `basename $0` <zip-file>"
    echo ""
    exit 1
}

[ "$1" = "" ] && Usage    
zipfile="$1"
destfolder="$2"
tmpdir=$(basename $zipfile | cut -d '.' -f 1)

mkdir -p $tmpdir
unzip $zipfile -d $tmpdir

echo ""
echo "Type:"
cmd="sudo rsync -avz --delete $tmpdir/*/  /FSL-scripts/"
echo $cmd
cmd="rm -rf $tmpdir"
echo $cmd
