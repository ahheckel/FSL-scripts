#!/bin/bash
trap 'echo "NOTE: An ERROR has occured."' ERR
set -e

destroot=/media/DATA/


dst=$destroot/skel_kira
rm -r $dst/*
src=/home/andi/kira_data

mkdir -p $dst/subj
mkdir -p $dst/grp/glm
cp $src/subj/subjects.all $dst/subj/subjects
cp $src/subj/config_* $dst/subj
cp $src/subj/template_* $dst/subj
cp $src/run_script.sh $dst
cp $src/globalfuncs $dst
cp $src/globalvars $dst
#cp $src/run_script.boldMNI $dst
cp $src/globalfuncs $dst
#cp $src/globalvars.boldMNI $dst
cp $src/grp/template_* $dst/grp
cp -Lr ~/misc $dst/
cp -r $src/grp/glm $dst/grp/
cp $src/reset.sh $dst
cd  $(dirname $dst) ; tar -czvf $(basename $dst).tar.gz $(basename $dst)


dst=$destroot/skel_neurospin
rm -r $dst/*
src=/home/andi/neurospin_test

mkdir -p $dst/subj
mkdir -p $dst/grp/glm/tbss
cp $src/subj/config_* $dst/subj
cp $src/subj/template_* $dst/subj
cp $src/run_script.sh $dst
cp $src/globalfuncs $dst
cp $src/globalvars $dst
cp $src/globalfuncs $dst
cp $src/grp/template_* $dst/grp
cp -r $src/grp/glm $dst/grp/
cp -Lr ~/misc $dst/
cp $src/subj/subjects.all $dst/subj/subjects
cp $src/convertfiles.sh $dst/
cp $src/reset.sh $dst
cd  $(dirname $dst) ; tar -czvf $(basename $dst).tar.gz $(basename $dst)


dst=$destroot/skel_script/studydir
rm -rf $dst/*
src=/home/andi/neurospin_test

mkdir -p $dst/subj
mkdir -p $dst/grp/glm/tbss
cp $src/subj/template_* $dst/subj
cp $src/run_script.sh $dst
cp $src/globalfuncs $dst
cp $src/globalvars $dst
cp $src/globalvars $dst/globalvars_neurospin
cp /home/andi/kira_data/globalvars $dst/globalvars_kira
cp $src/grp/template_* $dst/grp
cp $src/grp/glm/tbss/*.cmd $dst/grp/glm/tbss/
cp -Lr ~/misc $dst/
cd  $(dirname $dst) ; tar -czvf skel_script.tar.gz $(basename $dst) ; rm -f $destroot/skel_script.tar.gz ;  mv -f skel_script.tar.gz $destroot/

