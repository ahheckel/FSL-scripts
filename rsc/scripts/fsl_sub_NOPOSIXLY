#!/bin/sh

# Copyright (C) 2007 University of Oxford
# Authors: Dave Flitney & Stephen Smith

#   Part of FSL - FMRIB's Software Library
#   http://www.fmrib.ox.ac.uk/fsl
#   fsl@fmrib.ox.ac.uk
#   
#   Developed at FMRIB (Oxford Centre for Functional Magnetic Resonance
#   Imaging of the Brain), Department of Clinical Neurology, Oxford
#   University, Oxford, UK
#   
#   
#   LICENCE
#   
#   FMRIB Software Library, Release 4.0 (c) 2007, The University of
#   Oxford (the "Software")
#   
#   The Software remains the property of the University of Oxford ("the
#   University").
#   
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software,
#   or that it will be suitable for any particular purpose or for use
#   under any specific conditions. Furthermore, the University disclaims
#   all responsibility for the use which is made of the Software. It
#   further disclaims any liability for the outcomes arising from using
#   the Software.
#   
#   The Licensee agrees to indemnify the University and hold the
#   University harmless from and against any and all claims, damages and
#   liabilities asserted by third parties (including claims for
#   negligence) which arise directly or indirectly from the use of the
#   Software or the sale of any products based on the Software.
#   
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University. The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product. You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#   
#   You are not permitted under this Licence to use this Software
#   commercially. Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the
#   Software or any derivative of it for research with the final aim of
#   developing software products for sale or license to a third party or
#   (3) use of the Software or any derivative of it for research with the
#   final aim of developing non-software products for sale or license to a
#   third party, or (4) use of the Software to provide any service to an
#   external organisation for which payment is received. If you are
#   interested in using the Software commercially, please contact Isis
#   Innovation Limited ("Isis"), the technology transfer company of the
#   University, to negotiate a licence. Contact details are:
#   innovation@isis.ox.ac.uk quoting reference DE/1112.






###########################################################################
# Edit this file in order to setup FSL to use your local compute
# cluster.
###########################################################################

fslcluster_cell_settings=/usr/local/share/sge/default/common/settings.sh
# Domain mail should be sent to if necessary. The complete address will be
# `whoami`@${fslcluster_mailto_domain}
fslcluster_mailto_domain=localhost
# When should the cluster engine send status email (see qsub -m ... docs)
# Don't send email by default; can be overidden by FSLCLUSTER_MAILOPTS
# environment variable
fslcluster_mailopts="n"


###########################################################################
# The following section determines what to do when fsl_sub is called
# by an FSL program. If it finds a local cluster if will pass the
# commands onto the cluster. Otherwise it will run the commands
# itself. There are two values for the METHOD variable, "SGE" and
# "NONE". You should setup the tests to look for whether the calling
# computer can see your cluster setup scripts, and run them (if that's
# what you want, i.e. if you haven't already run them in the user's
# login scripts). Note that these tests look for the environment
# variable SGE_ROOT, which a user can unset if they don't want the
# cluster to be used.
###########################################################################

# try autodetecting SGE, but see ovveride switch FSLPARALLEL below
METHOD=SGE
if [ "x$SGE_ROOT" = "x" ] ; then
    if [ -f ${fslcluster_cell_settings} ] ; then
	. ${fslcluster_cell_settings}
    elif [ -f /usr/local/sge/default/common/settings.sh ] ; then
	. /usr/local/sge/default/common/settings.sh
    else
	METHOD=NONE
    fi
fi

# define the default 'qsub' implementation to be used for cluster submission
qsub_cmd="qsub"

# Allow to override the above automatic detection result with FSLPARALLEL
if [ -n "$FSLPARALLEL" ] ; then
    # Whenever FSLPARALLEL is set enfore using SGE even if no SGE_ROOT is set
    # which, for example, is the case on Debian systems running SGE
    METHOD=SGE
    # TODO: move cluster engine detection here to be able to support more than
    #       just SGE
    if [ "$FSLPARALLEL" = "condor" ] ; then
        # if condor shall be used, simply switch to Condor's qsub emulation
        qsub_cmd="condor_qsub"
    fi
fi

# Allow overriding mail settings
if [ "x$FSLCLUSTER_MAILOPTS" != "x" ] ; then
    fslcluster_mailopts=${FSLCLUSTER_MAILOPTS}
fi


###########################################################################
# Don't change the following (but keep scrolling down!)
###########################################################################

# POSIXLY_CORRECT=1 # commented out by HKL
# export POSIXLY_CORRECT # commented out by HKL
command=`basename $0`

usage ()
{
  cat <<EOF

$command V1.0beta - wrapper for job control system such as SGE

Usage: $command [options] <command>

$command gzip *.img *.hdr
$command -q short.q gzip *.img *.hdr
$command -a darwin regscript rawdata outputdir ...

  -T <minutes>          Estimated job length in minutes, used to let SGE select
                        an appropriate queue
  -q <queuename>        Possible values for <queuename> can be queried with
                        'qconf -sql'
  -a <arch-name>        Architecture [e.g., darwin or lx24-amd64]
  -p <job-priority>     Lower priority [0:-1024] default = 0                 
  -M <email-address>    Who to email, default = `whoami`@localhost
  -j <jid>              Place a hold on this task until job jid has completed
  -t <filename>         Specify a task file of commands to execute in parallel
  -N <jobname>          Specify jobname as it will appear on queue
  -l <logdirname>       Where to output logfiles
  -m <mailoptions>      Change the SGE mail options, see qsub for details
  -F                    Use flags embedded in scripts to set SGE queuing options
  -v                    Verbose mode.
EOF

  exit 1
}

nargs=$#
if [ $nargs -eq 0 ] ; then
  usage
fi

set -- `getopt T:q:a:p:M:j:t:N:Fvm:l: $*`
result=$?
if [ $result != 0 ] ; then
  echo "What? Your arguments make no sense!"
fi

if [ $nargs -eq 0 ] || [ $result != 0 ] ; then
  usage
fi


###########################################################################
# The following sets up the default queue name, which you may want to
# change. It also sets up the basic emailing control.
###########################################################################

# SGE should already have a default queue
#queue=long.q
mailto=`whoami`@${fslcluster_mailto_domain}
MailOpts=${fslcluster_mailopts}


###########################################################################
# In the following, you might want to change the behaviour of some
# flags so that they prepare the right arguments for the actual
# cluster queue submission program, in our case "qsub".
#
# -a sets is the cluster submission flag for controlling the required
# hardware architecture (normally not set by the calling program)
#
# -p set the priority of the job - ignore this if your cluster
# environment doesn't have priority control in this way.
#
# -j tells the cluster not to start this job until cluster job ID $jid
# has completed. You will need this feature.
#
# -t will pass on to the cluster software the name of a text file
# containing a set of commands to run in parallel; one command per
# line.
#
# -N option determines what the command will be called when you list
# running processes.
#
# -l tells the cluster what to call the standard output and standard
# -error logfiles for the submitted program.
###########################################################################

if [ -z $FSLSUBVERBOSE ] ; then
    verbose=0
else
    verbose=$FSLSUBVERBOSE;
    echo "METHOD=$METHOD : args=$@" >&2
fi

scriptmode=0

while [ $1 != -- ] ; do
  case $1 in
    -T)
      # qsub wants the time limit in seconds
      job_timelimit="-l h_rt=$(echo "$2 * 60" | bc)"
      shift;;
    -q)
      queue="-q $2"
      shift;;
    -a)
      acceptable_arch=no
      available_archs=`qhost | tail -n +4 | awk '{print $2}' | sort | uniq`
      for a in $available_archs; do
	if [ $2 = $a ] ; then
	  acceptable_arch=yes
	fi
      done
      if [ $acceptable_arch = yes ]; then
	  sge_arch="-l arch=$2"
      else
	  echo "Sorry arch of $2 is not supported on this SGE configuration!"
	  echo "Should be one of:" $available_archs
	  exit 127
      fi
      shift;;
    -p)
      sge_priority="-p $2"
      shift;;
    -M)
      mailto=$2
      shift;;
    -j)
      jid=$2
      sge_hold="-hold_jid $jid"
      shift;;
    -t)
      taskfile=$2
      tasks=`wc -l $taskfile | awk '{print $1}'`
      sge_tasks="-t 1-$tasks"
      shift;;
    -N)
      JobName=$2;
      shift;;
    -m)
      MailOpts=$2;
      shift;;
    -l)
      LogOpts="-o $2 -e $2";
      LogDir="${2}/";
      mkdir -p $2;
      shift;;
    -F)
      scriptmode=1;
      ;;
    -v)
      verbose=1
      ;;
  esac
  shift  # next flag
done
shift

###########################################################################
# Don't change the following (but keep scrolling down!)
###########################################################################

if [ "x$JobName" = x ] ; then 
    if [ "x$taskfile" != x ] ; then
	JobName=`basename $taskfile`
    else
	JobName=`basename $1`
    fi
fi

if [ "x$tasks" != x ] && [ ! -f "$taskfile" ] ; then
    echo $taskfile: invalid input!
    echo Should be a text file listing all the commands to run!
    exit -1
fi

if [ "x$tasks" != "x" ] && [ "x$@" != "x" ] ; then
    echo $@
    echo Spurious input after parsing command line!
    exit -1
fi

case $METHOD in

###########################################################################
# The following is the main call to the cluster, using the "qsub" SGE
# program. If $tasks has not been set then qsub is running a single
# command, otherwise qsub is processing a text file of parallel
# commands.
###########################################################################

    SGE)
	if [ "x$tasks" = "x" ] ; then
	    if [ $scriptmode -ne 1 ] ; then
		sge_command="$qsub_cmd -V -cwd -shell n -b y -r y $job_timelimit $queue -M $mailto -N $JobName -m $MailOpts $LogOpts $sge_arch $sge_hold"
	    else
		sge_command="$qsub_cmd $LogOpts $sge_arch $sge_hold"
	    fi
	    if [ $verbose -eq 1 ] ; then 
		echo sge_command: $sge_command >&2
		echo executing: $@ >&2
	    fi
	    exec $sge_command $@ | awk '{print $3}'
	else
	    sge_command="$qsub_cmd -V -cwd $job_timelimit $queue -M $mailto -N $JobName -m $MailOpts $LogOpts $sge_arch $sge_hold $sge_tasks"
	    if [ $verbose -eq 1 ] ; then 
		echo sge_command: $sge_command >&2
		echo control file: $taskfile >&2
	    fi
	    exec $sge_command <<EOF | awk '{print $3}' | awk -F. '{print $1}'
#!/bin/sh

#$ -S /bin/sh

command=\`sed -n -e "\${SGE_TASK_ID}p" $taskfile\`

exec /bin/sh -c "\$command"
EOF
	fi
	;;

###########################################################################
# Don't change the following - this runs the commands directly if a
# cluster is not being used.
###########################################################################

    NONE)
	if [ "x$tasks" = "x" ] ; then
	    if [ $verbose -eq 1 ] ; then 
		echo executing: $@ >&2
	    fi

	    /bin/sh <<EOF1 > ${LogDir}${JobName}.o$$ 2> ${LogDir}${JobName}.e$$
$@
EOF1
	else
	    if [ $verbose -eq 1 ] ; then 
		echo "Running commands in: $taskfile" >&2
	    fi

	    n=1
	    while [ $n -le $tasks ] ; do
		line=`sed -n -e ''${n}'p' $taskfile`
		if [ $verbose -eq 1 ] ; then 
		    echo executing: $line >&2
		fi
		/bin/sh <<EOF2 > ${LogDir}${JobName}.o$$.$n 2> ${LogDir}${JobName}.e$$.$n
$line
EOF2
		n=`expr $n + 1`
	    done
	fi	
	echo $$
	;;

esac

###########################################################################
# Done.
###########################################################################

