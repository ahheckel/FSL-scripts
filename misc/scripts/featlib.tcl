#{{{ copyright and setup 

#   FEAT TCL functions library
#
#   Stephen Smith, Matthew Webster & Mark Jenkinson  FMRIB Analysis Group
#
#   Copyright (C) 1999-2010 University of Oxford
#
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

#}}}

### general procs
#{{{ feat5:write

proc feat5:write { w feat_model write_image_filenames exitoncheckfail filename } {

    global fmri FSLDIR feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files confoundev_files

    if { ! $fmri(inmelodic) && $fmri(level) == 1 && $fmri(analysis) > 0 && $fmri(con_mode) == "orig" && [ feat5:setup_model_update_contrasts_mode $w 0] == -1 } {
	return -1
    }

    set filename [ file rootname $filename ]

    if { $fmri(level) > 1 } {
	set fmri(npts) $fmri(multiple)
	set fmri(ndelete) 0
    }

    set channel [ open ${filename}.fsf "w" ]

    #{{{ basic variables

    puts $channel "
# FEAT version number
set fmri(version) $fmri(version)

# Are we in MELODIC?
set fmri(inmelodic) $fmri(inmelodic)

# Analysis level
# 1 : First-level analysis
# 2 : Higher-level analysis
set fmri(level) $fmri(level)

# Which stages to run
# 0 : No first-level analysis (registration and/or group stats only)
# 7 : Full first-level analysis
# 1 : Pre-Stats
# 3 : Pre-Stats + Stats
# 2 :             Stats
# 6 :             Stats + Post-stats
# 4 :                     Post-stats
set fmri(analysis) $fmri(analysis)

# Use relative filenames
set fmri(relative_yn) $fmri(relative_yn)

# Balloon help
set fmri(help_yn) $fmri(help_yn)

# Run Featwatcher
set fmri(featwatcher_yn) $fmri(featwatcher_yn)

# Cleanup first-level standard-space images
set fmri(sscleanup_yn) $fmri(sscleanup_yn)

# Output directory
set fmri(outputdir) \"$fmri(outputdir)\"

# TR(s)
set fmri(tr) $fmri(tr)

# Total volumes
set fmri(npts) $fmri(npts)

# Delete volumes
set fmri(ndelete) $fmri(ndelete)

# Perfusion tag/control order
set fmri(tagfirst) $fmri(tagfirst)

# Number of first-level analyses
set fmri(multiple) $fmri(multiple)

# Higher-level input type
# 1 : Inputs are lower-level FEAT directories
# 2 : Inputs are cope images from FEAT directories
set fmri(inputtype) $fmri(inputtype)

# Carry out pre-stats processing?
set fmri(filtering_yn) $fmri(filtering_yn)

# Brain/background threshold, %
set fmri(brain_thresh) $fmri(brain_thresh)

# Critical z for design efficiency calculation
set fmri(critical_z) $fmri(critical_z)

# Noise level
set fmri(noise) $fmri(noise)

# Noise AR(1)
set fmri(noisear) $fmri(noisear)

# Post-stats-only directory copying
# 0 : Overwrite original post-stats results
# 1 : Copy original FEAT directory for new Contrasts, Thresholding, Rendering
set fmri(newdir_yn) $fmri(newdir_yn)

# Motion correction
# 0 : None
# 1 : MCFLIRT
set fmri(mc) $fmri(mc)

# Spin-history (currently obsolete)
set fmri(sh_yn) $fmri(sh_yn)

# B0 fieldmap unwarping?
set fmri(regunwarp_yn) $fmri(regunwarp_yn)

# EPI dwell time (ms)
set fmri(dwell) $fmri(dwell)

# EPI TE (ms)
set fmri(te) $fmri(te)

# % Signal loss threshold
set fmri(signallossthresh) $fmri(signallossthresh)

# Unwarp direction
set fmri(unwarp_dir) $fmri(unwarp_dir)

# Slice timing correction
# 0 : None
# 1 : Regular up (0, 1, 2, 3, ...)
# 2 : Regular down
# 3 : Use slice order file
# 4 : Use slice timings file
# 5 : Interleaved (0, 2, 4 ... 1, 3, 5 ... )
set fmri(st) $fmri(st)

# Slice timings file
set fmri(st_file) \"$fmri(st_file)\"

# BET brain extraction
set fmri(bet_yn) $fmri(bet_yn)

# Spatial smoothing FWHM (mm)
set fmri(smooth) $fmri(smooth)

# Intensity normalization
set fmri(norm_yn) $fmri(norm_yn)

# Perfusion subtraction
set fmri(perfsub_yn) $fmri(perfsub_yn)

# Highpass temporal filtering
set fmri(temphp_yn) $fmri(temphp_yn)

# Lowpass temporal filtering
set fmri(templp_yn) $fmri(templp_yn)

# MELODIC ICA data exploration
set fmri(melodic_yn) $fmri(melodic_yn)

# Carry out main stats?
set fmri(stats_yn) $fmri(stats_yn)

# Carry out prewhitening?
set fmri(prewhiten_yn) $fmri(prewhiten_yn)

# Add motion parameters to model
# 0 : No
# 1 : Yes
set fmri(motionevs) $fmri(motionevs)

# Robust outlier detection in FLAME?
set fmri(robust_yn) $fmri(robust_yn)

# Higher-level modelling
# 3 : Fixed effects
# 0 : Mixed Effects: Simple OLS
# 2 : Mixed Effects: FLAME 1
# 1 : Mixed Effects: FLAME 1+2
set fmri(mixed_yn) $fmri(mixed_yn)

# Number of EVs
set fmri(evs_orig) $fmri(evs_orig)
set fmri(evs_real) $fmri(evs_real)
set fmri(evs_vox) $fmri(evs_vox)

# Number of contrasts
set fmri(ncon_orig) $fmri(ncon_orig)
set fmri(ncon_real) $fmri(ncon_real)

# Number of F-tests
set fmri(nftests_orig) $fmri(nftests_orig)
set fmri(nftests_real) $fmri(nftests_real)

# Add constant column to design matrix? (obsolete)
set fmri(constcol) $fmri(constcol)

# Carry out post-stats steps?
set fmri(poststats_yn) $fmri(poststats_yn)

# Pre-threshold masking?
set fmri(threshmask) \"$fmri(threshmask)\"

# Thresholding
# 0 : None
# 1 : Uncorrected
# 2 : Voxel
# 3 : Cluster
set fmri(thresh) $fmri(thresh)

# P threshold
set fmri(prob_thresh) $fmri(prob_thresh)

# Z threshold
set fmri(z_thresh) $fmri(z_thresh)

# Z min/max for colour rendering
# 0 : Use actual Z min/max
# 1 : Use preset Z min/max
set fmri(zdisplay) $fmri(zdisplay)

# Z min in colour rendering
set fmri(zmin) $fmri(zmin)

# Z max in colour rendering
set fmri(zmax) $fmri(zmax)

# Colour rendering type
# 0 : Solid blobs
# 1 : Transparent blobs
set fmri(rendertype) $fmri(rendertype)

# Background image for higher-level stats overlays
# 1 : Mean highres
# 2 : First highres
# 3 : Mean functional
# 4 : First functional
# 5 : Standard space template
set fmri(bgimage) $fmri(bgimage)

# Create time series plots
set fmri(tsplot_yn) $fmri(tsplot_yn)

# Registration?
set fmri(reg_yn) $fmri(reg_yn)

# Registration to initial structural
set fmri(reginitial_highres_yn) $fmri(reginitial_highres_yn)

# Search space for registration to initial structural
# 0   : No search
# 90  : Normal search
# 180 : Full search
set fmri(reginitial_highres_search) $fmri(reginitial_highres_search)

# Degrees of Freedom for registration to initial structural
set fmri(reginitial_highres_dof) $fmri(reginitial_highres_dof)

# Registration to main structural
set fmri(reghighres_yn) $fmri(reghighres_yn)

# Search space for registration to main structural
# 0   : No search
# 90  : Normal search
# 180 : Full search
set fmri(reghighres_search) $fmri(reghighres_search)

# Degrees of Freedom for registration to main structural
set fmri(reghighres_dof) $fmri(reghighres_dof)

# Registration to standard image?
set fmri(regstandard_yn) $fmri(regstandard_yn)

# Standard image
set fmri(regstandard) \"$fmri(regstandard)\"

# Search space for registration to standard space
# 0   : No search
# 90  : Normal search
# 180 : Full search
set fmri(regstandard_search) $fmri(regstandard_search)

# Degrees of Freedom for registration to standard space
set fmri(regstandard_dof) $fmri(regstandard_dof)

# Do nonlinear registration from structural to standard space?
set fmri(regstandard_nonlinear_yn) $fmri(regstandard_nonlinear_yn)

# Control nonlinear warp field resolution
set fmri(regstandard_nonlinear_warpres) $fmri(regstandard_nonlinear_warpres) 

# High pass filter cutoff
set fmri(paradigm_hp) $fmri(paradigm_hp)"

#}}}
    #{{{ input and highres filenames

puts $channel "
# Number of lower-level copes feeding into higher-level analysis
set fmri(ncopeinputs) $fmri(ncopeinputs)"
for { set nci 1 } { $nci <=  $fmri(ncopeinputs) } { incr nci 1 } {   
	puts $channel "
# Use lower-level cope $nci for higher-level analysis
set fmri(copeinput.$nci) $fmri(copeinput.$nci)"
}

if { $write_image_filenames } {

if { $fmri(multiple) > 0 } {
    if { $w != -1 } {
	if { [ feat5:multiple_check $w 0 0 0 d ] && $exitoncheckfail } {
	    return 1
	}
    }
    for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
	puts $channel "
# 4D AVW data or FEAT directory ($i)
set feat_files($i) \"$feat_files($i)\""
    }
    puts $channel "
# Add confound EVs text file
set fmri(confoundevs) $fmri(confoundevs)"
    if { $w != -1 && $fmri(confoundevs) } {
	if { [ feat5:multiple_check $w 20 0 0 d ] && $exitoncheckfail } {
	    return 1
	}
	for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
	    puts $channel "
# Confound EVs text file for analysis $i
set confoundev_files($i) \"$confoundev_files($i)\""
	}
    }
}


if { $fmri(reg_yn) && ( $fmri(regunwarp_yn) || $fmri(reginitial_highres_yn) || $fmri(reghighres_yn) ) } {

    if { $fmri(multiple) < 2 } {
	set nhighres 1
    } else {
	set nhighres $fmri(multiple)
    }

    if { $fmri(relative_yn) } {
	for { set i 1 } { $i <= $nhighres } { incr i 1 } {
	    set unwarp_files($i) [ file dirname $feat_files($i) ]/blahstruct_brain.hdr
	    set initial_highres_files($i) [ file dirname $feat_files($i) ]/struct_brain.hdr
	    set highres_files($i) [ file dirname $feat_files($i) ]/blah2struct_brain.hdr
	}
    }

    if { $w != -1 } {
	if { $fmri(regunwarp_yn) } {
	    if { [ feat5:multiple_check $w 1 0 0 d ] && $exitoncheckfail } {
		return 1
	    }
	    for { set i 1 } { $i <= $nhighres } { incr i 1 } {
		puts $channel "
# B0 unwarp input image for analysis $i
set unwarp_files($i) \"$unwarp_files($i)\""
            }
	    if { [ feat5:multiple_check $w 2 0 0 d ] && $exitoncheckfail } {
		return 1
	    }
	    for { set i 1 } { $i <= $nhighres } { incr i 1 } {
		puts $channel "
# B0 unwarp mag input image for analysis $i
set unwarp_files_mag($i) \"$unwarp_files_mag($i)\""
            }
	}
	if { $fmri(reginitial_highres_yn) } {
	    if { [ feat5:multiple_check $w 3 0 0 d ] && $exitoncheckfail } {
		return 1
	    }
	    for { set i 1 } { $i <= $nhighres } { incr i 1 } {
		puts $channel "
# Session's structural image for analysis $i
set initial_highres_files($i) \"$initial_highres_files($i)\""
            }
	}
	if { $fmri(reghighres_yn) } {
	    if { [ feat5:multiple_check $w 4 0 0 d ] && $exitoncheckfail } {
		return 1
	    }
	    for { set i 1 } { $i <= $nhighres } { incr i 1 } {
		puts $channel "
# Subject's structural image for analysis $i
set highres_files($i) \"$highres_files($i)\""
            }
	}
    }
}

} else { 
    if { $fmri(npts) < 1 } {
	MxPause "Please either select input data or set the number of total volumes before attempting to view the design."
	if { $exitoncheckfail } {
	    return -1
	}
    }
}

#}}}
    if { ! $fmri(inmelodic) } {
	#{{{ EVs

	for { set i 1 } { $i <= $fmri(evs_orig) } { incr i 1 } {

	    puts $channel "
# EV $i title
set fmri(evtitle$i) \"$fmri(evtitle$i)\""

	    if { [ info exists fmri(shape$i) ] } {

		puts $channel "
# Basic waveform shape (EV $i)
# 0 : Square
# 1 : Sinusoid
# 2 : Custom (1 entry per volume)
# 3 : Custom (3 column format)
# 4 : Interaction
# 10 : Empty (all zeros)
set fmri(shape$i) $fmri(shape$i)

# Convolution (EV $i)
# 0 : None
# 1 : Gaussian
# 2 : Gamma
# 3 : Double-Gamma HRF
# 4 : Gamma basis functions
# 5 : Sine basis functions
# 6 : FIR basis functions
set fmri(convolve$i) $fmri(convolve$i)

# Convolve phase (EV $i)
set fmri(convolve_phase$i) $fmri(convolve_phase$i)

# Apply temporal filtering (EV $i)
set fmri(tempfilt_yn$i) $fmri(tempfilt_yn$i)

# Add temporal derivative (EV $i)
set fmri(deriv_yn$i) $fmri(deriv_yn$i)"

		switch $fmri(shape$i) {
		    0 { 
			puts $channel "
# Skip (EV $i)
set fmri(skip$i) $fmri(skip$i)

# Off (EV $i)
set fmri(off$i) $fmri(off$i)

# On (EV $i)
set fmri(on$i) $fmri(on$i)

# Phase (EV $i)
set fmri(phase$i) $fmri(phase$i)

# Stop (EV $i)
set fmri(stop$i) $fmri(stop$i)"
		    }
		    1 { 
			puts $channel "
# Skip (EV $i)
set fmri(skip$i) $fmri(skip$i)

# Period (EV $i)
set fmri(period$i) $fmri(period$i)

# Phase (EV $i)
set fmri(phase$i) $fmri(phase$i)

# Sinusoid harmonics (EV $i)
set fmri(nharmonics$i) $fmri(nharmonics$i) 

# Stop (EV $i)
set fmri(stop$i) $fmri(stop$i)"
		    }
		    2 { puts $channel "
# Custom EV file (EV $i)
set fmri(custom$i) \"$fmri(custom$i)\"" }
		    3 { puts $channel "
# Custom EV file (EV $i)
set fmri(custom$i) \"$fmri(custom$i)\"" }
		    4 {
			for { set j 1 } { $j < $i } { incr j 1 } {
			    puts $channel "
# Interactions (EV $i with EV $j)
set fmri(interactions${i}.$j) $fmri(interactions${i}.$j)

# Demean before using in interactions (EV $i with EV $j)
set fmri(interactionsd${i}.$j) $fmri(interactionsd${i}.$j)"
			}
		    }
		}
		
		switch $fmri(convolve$i) {
		    0 { }
		    1 { 
			puts $channel "
# Gauss sigma (EV $i)
set fmri(gausssigma$i) $fmri(gausssigma$i)

# Gauss delay (EV $i)
set fmri(gaussdelay$i) $fmri(gaussdelay$i)"
		    }
		    2 {
			puts $channel "
# Gamma sigma (EV $i)
set fmri(gammasigma$i) $fmri(gammasigma$i)

# Gamma delay (EV $i)
set fmri(gammadelay$i) $fmri(gammadelay$i)"
		    }
		    3 { }
		    4 {
			puts $channel "
# Gamma basis functions number (EV $i)
set fmri(basisfnum$i) $fmri(basisfnum$i)

# Gamma basis functions window(s) (EV $i)
set fmri(basisfwidth$i) $fmri(basisfwidth$i)

# Orth basis functions wrt each other
set fmri(basisorth$i) $fmri(basisorth$i)"
                    }
		    5 {
			puts $channel "
# Sine basis functions number (EV $i)
set fmri(basisfnum$i) $fmri(basisfnum$i)

# Sine basis functions window(s) (EV $i)
set fmri(basisfwidth$i) $fmri(basisfwidth$i)

# Orth basis functions wrt each other
set fmri(basisorth$i) $fmri(basisorth$i)"
                    }
		    6 {
			puts $channel "
# FIR basis functions number (EV $i)
set fmri(basisfnum$i) $fmri(basisfnum$i)

# FIR basis functions window(s) (EV $i)
set fmri(basisfwidth$i) $fmri(basisfwidth$i)

# Orth basis functions wrt each other
set fmri(basisorth$i) $fmri(basisorth$i)"
                    }
		    7 {
			puts $channel "
# FIR basis functions number (EV $i)
set fmri(basisfnum$i) $fmri(basisfnum$i)

# Optimal/custom HRF convolution file (EV $i)
set fmri(bfcustom$i) \"$fmri(bfcustom$i)\"

# Orth basis functions wrt each other
set fmri(basisorth$i) $fmri(basisorth$i)"
                    }
		}

		for { set j 0 } { $j <= $fmri(evs_orig) } { incr j 1 } {
		    puts $channel "
# Orthogonalise EV $i wrt EV $j
set fmri(ortho${i}.$j) $fmri(ortho${i}.$j)"
		}

		if { $fmri(level) > 1 } {
		    for { set j 1 } { $j <= $fmri(npts) } { incr j 1 } {
			puts $channel "
# Higher-level EV value for EV $i and input $j
set fmri(evg${j}.$i) $fmri(evg${j}.$i)"
		    }
		}
		
	    }
	}

	if { $fmri(level) > 1 } {
	    if { [ info exists fmri(level2orth) ] } {
		puts $channel "
# Setup Orthogonalisation at higher level? 
set fmri(level2orth) $fmri(level2orth)"
	    }

            for { set j 1 } { $j <= $fmri(multiple) } { incr j 1 } {
		puts $channel "
# Group membership for input $j
set fmri(groupmem.$j) $fmri(groupmem.$j)"
            }
	}

for { set i 1 } { $i <= $fmri(evs_vox) } { incr i 1 } {
    puts $channel "
# EV [ expr $i + $fmri(evs_orig) ] voxelwise image filename
set fmri(evs_vox_$i) \"$fmri(evs_vox_$i)\""
}

#}}}
	#{{{ contrasts & F-tests

puts $channel "
# Contrast & F-tests mode
# real : control real EVs
# orig : control original EVs
set fmri(con_mode_old) $fmri(con_mode)
set fmri(con_mode) $fmri(con_mode)"

if { $fmri(level) == 1 } {
    set modes "real orig"
} else {
    set modes real
}

foreach cm $modes {

    for { set i 1 } { $i <= $fmri(ncon_${cm}) } { incr i 1 } {

	puts $channel "
# Display images for contrast_${cm} $i
set fmri(conpic_${cm}.$i) $fmri(conpic_${cm}.$i)

# Title for contrast_${cm} $i
set fmri(conname_${cm}.$i) \"$fmri(conname_${cm}.$i)\""

        for { set j 1 } { $j <= $fmri(evs_${cm}) } { incr j 1 } {
	    puts $channel "
# Real contrast_${cm} vector $i element $j
set fmri(con_${cm}${i}.${j}) $fmri(con_${cm}${i}.${j})"
        }

	for { set j 1 } { $j <= $fmri(nftests_${cm}) } { incr j 1 } {
	    puts $channel "
# F-test $j element $i
set fmri(ftest_${cm}${j}.${i}) $fmri(ftest_${cm}${j}.${i})"
        }

    }

}

puts $channel "
# Contrast masking - use >0 instead of thresholding?
set fmri(conmask_zerothresh_yn) $fmri(conmask_zerothresh_yn)"

set total [ expr $fmri(ncon_real) + $fmri(nftests_real) ]
set fmri(conmask1_1) 0
for { set c 1 } { $c <= $total } { incr c } {
    for { set C 1 } { $C <= $total } { incr C } {
	if { $C != $c } {
	    if { ! [ info exists fmri(conmask${c}_${C}) ] } {
		set fmri(conmask${c}_${C}) 0
	    }
	    puts $channel "
# Mask real contrast/F-test $c with real contrast/F-test $C?
set fmri(conmask${c}_${C}) $fmri(conmask${c}_${C})"

	    if { $fmri(conmask${c}_${C}) } {
		set fmri(conmask1_1) 1
	    }
	}
    }
}

puts $channel "
# Do contrast masking at all?
set fmri(conmask1_1) $fmri(conmask1_1)"

#}}}
    } else {
	#{{{ MELODIC

puts $channel "
# Resampling resolution
set fmri(regstandard_res) $fmri(regstandard_res)

# Variance-normalise timecourses
set fmri(varnorm) $fmri(varnorm)

# Automatic dimensionality estimation
set fmri(dim_yn) $fmri(dim_yn)

# Output components
set fmri(dim) $fmri(dim)

# 1 : Single-session ICA
# 2 : Multi-session temporal concatenation
# 3 : Multi-session tensor TICA
set fmri(icaopt) $fmri(icaopt)

# Threshold IC maps
set fmri(thresh_yn) $fmri(thresh_yn)

# Mixture model threshold
set fmri(mmthresh) $fmri(mmthresh)

# Output full stats folder
set fmri(ostats) $fmri(ostats)

# Timeseries and subject models
set fmri(ts_model_mat) \"$fmri(ts_model_mat)\"
set fmri(ts_model_con) \"$fmri(ts_model_con)\"
set fmri(subject_model_mat) \"$fmri(subject_model_mat)\"
set fmri(subject_model_con) \"$fmri(subject_model_con)\"
"

#}}}
    }
    #{{{ non-GUI options

    puts $channel "
##########################################################
# Now options that don't appear in the GUI

# Alternative example_func image (not derived from input 4D dataset)
set fmri(alternative_example_func) \"$fmri(alternative_example_func)\"

# Alternative (to BETting) mask image
set fmri(alternative_mask) \"$fmri(alternative_mask)\"

# Initial structural space registration initialisation transform
set fmri(init_initial_highres) \"$fmri(init_initial_highres)\"

# Structural space registration initialisation transform
set fmri(init_highres) \"$fmri(init_highres)\"

# Standard space registration initialisation transform
set fmri(init_standard) \"$fmri(init_standard)\"

# For full FEAT analysis: overwrite existing .feat output dir?
set fmri(overwrite_yn) $fmri(overwrite_yn)"

#}}}

    close $channel
    
    if { $w != -1 } {
	set result 0
	set fmri(donemodel) 1
	if { $feat_model } {

	    set conf ""
	    if { $fmri(confoundevs) } {
		set conf "$confoundev_files(1)"
	    }
	    set result [ catch { exec sh -c "${FSLDIR}/bin/feat_model $filename $conf" } ErrMsg ]
	    if {$result != 0 || [ string length $ErrMsg ] > 0 } {
		MxPause "Problem with processing the model: $ErrMsg"
	    }
	}

	return $result
    }
}

#}}}
#{{{ feat5:load

proc feat5:load { w full filename } {
    global fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files confoundev_files

    set FEATVERSION $fmri(version)
    set INMELODIC [ exec sh -c "grep -a 'fmri(inmelodic)' $filename | tail -n 1 | awk '{ print \$3 }'" ]

    if { $INMELODIC != 1 } {

	set version [ exec sh -c "grep -a 'fmri(version)' $filename | awk '{ print \$3 }'" ]
    
	if { $version > 4.99 } {

	    if { $w != -1 } {
		set level    $fmri(level)
		set analysis $fmri(analysis)
		set multiple $fmri(multiple)
		set reg_yn   $fmri(reg_yn)
		for { set i 1 } { $i <= $multiple } { incr i 1 } {
		    if { [ info exists feat_files($i) ] } {
			set lfeat_files($i) $feat_files($i)
		    }
		}
	    }

	    source ${filename}

	    if { $w != -1 && $fmri(analysis) != 4 && $fmri(analysis) != 0 } {
		feat5:updateimageinfo $w 1 0
	    }
	    
	    if { ! $full } {
		if { $level != $fmri(level) } {
		    feat5:updatelevel $w 
		    set fmri(level) $level
		}

		set fmri(npts) [ expr $fmri(npts) - $fmri(ndelete) ]
		set fmri(ndelete) 0
		set fmri(reg_yn)   $reg_yn
		set fmri(analysis) $analysis
		set fmri(multiple) $multiple
		for { set i 1 } { $i <= $multiple } { incr i 1 } {
		    set feat_files($i) $lfeat_files($i)
		}
	    }

	    if { $w != -1 } {
		feat5:updateanalysis $w
		feat5:updatehelp $w
		feat5:updateprestats $w
	    }

	    if { $fmri(motionevs) > 0 } {
		set fmri(motionevs) 1
	    }

	} else {
	    MxPause "FEAT setup file is too old to load - sorry!"
	    return 1
	}
    } else {
	source ${filename}
	if { $w != -1 } {
	    melodic:updatelevel $w
	    melodic:updatedim $w
	    feat5:updateanalysis $w
	}
    }
    
    set fmri(version) $FEATVERSION
    set fmri(donemodel) 1
}

#}}}
#{{{ parseatlases

proc parseatlas { atlasid filename } {
    global atlasname atlasimage atlaslabelcount atlaslabelid atlaslabelname
    set channel [ open $filename "r" ]
    set atlaslabelcount($atlasid) 0
    while { [ gets $channel instring ] >= 0 } {
	set isname [ string first "<name>" $instring ]
	if { $isname >= 0 } {
	    set atlasname($atlasid) [ string range $instring [ expr $isname + 6 ] [ expr [ string last "</name>" $instring ] - 1 ] ]
	    #puts $atlasname($atlasid)
	}
	set issummary [ string first "<imagefile>" $instring ]
	if { $issummary >= 0 } {
	    set atlasimage($atlasid) [ string range $instring [ expr $issummary + 11 ] [ expr [ string last "</imagefile>" $instring ] - 1 ] ]
	    #puts $atlasimage($atlasid)
	}
	set islabel [ string first "<label " $instring ]
	if { $islabel >= 0 } {
	    set atlaslabelid($atlasid,$atlaslabelcount($atlasid))   [ string range $instring [ expr [ string first "index=\"" $instring ] + 7 ] [ expr [ string first "\" x=\"" $instring ] - 1 ] ]
	    set atlaslabelname($atlasid,$atlaslabelcount($atlasid)) [ string range $instring [ expr [ string first "\">" $instring ] + 2 ] [ expr [ string first "</label>" $instring ] - 1 ] ]
	    #puts "$atlaslabelid($atlasid,$atlaslabelcount($atlasid)) $atlaslabelname($atlasid,$atlaslabelcount($atlasid))"
	    incr atlaslabelcount($atlasid) 1
	}
    }
    close $channel
}

proc parseatlases { } {
    global FSLDIR n_atlases atlasmenu atlasname atlasimage atlaslabelcount atlaslabelid atlaslabelname
    set atlaslist [ glob ${FSLDIR}/data/atlases/*.xml ]
    set n_atlases [ llength $atlaslist ]
    for { set atlasid 1 } { $atlasid <= $n_atlases } { incr atlasid 1 } {
	parseatlas $atlasid [ lindex $atlaslist [ expr $atlasid - 1 ] ]
	if { [ info exists atlasmenu ] } {
	    set atlasmenu "$atlasmenu $atlasid \"$atlasname($atlasid)\""
	}
    }
}

#}}}

### GUI procs
#{{{ feat5:setupdefaults

proc feat5:setupdefaults { } {
    global fmri FSLDIR HOME

    set fmri(version) 5.98

    set fmri(inmelodic) 0

    # load defaults (mandatory!)
    if { [ file exists ${FSLDIR}/etc/fslconf/feat.tcl ] } {
	source ${FSLDIR}/etc/fslconf/feat.tcl
    } else {
	MxPause "error: FEAT default settings file ${FSLDIR}/etc/fslconf/feat.tcl doesn't exist!"
	exit 1
    }

    # load user-specific defaults if they exist 
    if { [ file exists ${HOME}/.fslconf/feat.tcl ] } {
	source ${HOME}/.fslconf/feat.tcl
    }

    set fmri(design_help) "This is a graphical representation of the design matrix and parameter
contrasts.

The bar on the left is a representation of time, which starts at the
top and points downwards. The white marks show the position of every
10th volume in time. The red bar shows the period of the longest
temporal cycle which was passed by the highpass filtering.

The main top part shows the design matrix; time is represented on the
vertical axis and each column is a different (real) explanatory
variable (e.g., stimulus type). Both the red lines and the black-white
images represent the same thing - the variation of the waveform in
time.

Below this is shown the requested contrasts; each row is a different
contrast vector and each column refers to the weighting of the
relevant explanatory variable. Thus each row will result in a Z
statistic image.

If F-tests have been specified, these appear to the right of the
contrasts; each column is a different F-test, with the inclusion of
particular contrasts depicted by filled squares instead of empty
ones."

    set fmri(infeat) 1

    set fmri(filtering_yn) 1
    set fmri(sh_yn) 0
    set fmri(st_file) ""

    set fmri(stats_yn) 1
    set fmri(wizard_type) 1

    set fmri(poststats_yn) 1

    set fmri(threshmask) ""

    set fmri(reg_yn) 1

    set fmri(ncopeinputs) 0
    set fmri(inputtype) 1
    set fmri(multiple) 1
    set fmri(outputdir) ""
    set fmri(relative_yn) 0
    set fmri(constcol) 0
    set fmri(con_mode) orig
    set fmri(con_mode_old) orig
    set fmri(evs_orig) 1
    set fmri(evs_real) 1
    set fmri(ncon_real) 1
    set fmri(ncon_orig) 1
    set fmri(nftests_real) 0
    set fmri(nftests_orig) 0

    set fmri(feat_filename) [ exec sh -c "${FSLDIR}/bin/tmpnam /tmp/feat" ].fsf

    set fmri(regstandard_res) 0
    set fmri(ts_model_mat) ""
    set fmri(ts_model_con) ""
    set fmri(subject_model_mat) ""
    set fmri(subject_model_con) ""
}

#}}}
#{{{ feat5:scrollform_resize

proc feat5:scrollform_resize { w0 viewport } {

    set MAXWIDTH  950
    set MAXHEIGHT 600

    set fwidth  [ winfo width $viewport.f ]
    if { $fwidth > $MAXWIDTH } {
	set fwidth $MAXWIDTH
	pack $w0.xsbar -fill x -in $w0
    } else {
	pack forget $w0.f.xsbar
    }

    set fheight [ winfo height $viewport.f ]
    if { $fheight > $MAXHEIGHT } {
	set fheight $MAXHEIGHT
	pack $w0.f.ysbar -side right -fill y -in $w0.f
    } else {
	pack forget $w0.f.ysbar
    }

    $viewport configure -width $fwidth -height $fheight -scrollregion [ $viewport bbox all ]
}

#}}}
#{{{ feat5:multiple_select

proc feat5:multiple_select { w which_files windowtitle } {
    global FSLDIR fmri VARS PWD feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files confoundev_files

    #{{{ setup window

    set count 0
    set w0 ".dialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".dialog[incr count]"
    }

    toplevel $w0

    wm iconname $w0 "Select"
    wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm

    wm title $w0 $windowtitle

    frame $w0.f
    pack $w0.f -expand yes -fill both -in $w0 -side top

    canvas $w0.f.viewport -yscrollcommand "$w0.f.ysbar set"
    scrollbar $w0.f.ysbar -command "$w0.f.viewport yview" -orient vertical
    frame $w0.f.viewport.f
    $w0.f.viewport create window 0 0 -anchor nw -window $w0.f.viewport.f
    bind $w0.f.viewport.f <Configure> "feat5:scrollform_resize $w0 $w0.f.viewport"
    pack $w0.f.viewport -side left -fill both -expand true -in $w0.f

#}}}
    #{{{ setup file selections

set pastevar feat_files

for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
    if { $which_files < 1 } {
	if { ( $fmri(level) == 1 && $fmri(analysis) != 4 && $fmri(analysis) != 0 ) || $fmri(inputtype) == 2 } {
            FileEntry $w0.filename$i -textvariable feat_files($i) -filetypes IMAGE 
	} else {
            FileEntry $w0.filename$i -textvariable feat_files($i) -filetypes *.feat -dirasfile design.fsf
	}
    } elseif { $which_files == 1 } {
        FileEntry $w0.filename$i -textvariable unwarp_files($i) -filetypes IMAGE 
	set pastevar unwarp_files
    } elseif { $which_files == 2 } {
         FileEntry $w0.filename$i -textvariable unwarp_files_mag($i) -filetypes IMAGE 
	set pastevar unwarp_files_mag
    } elseif { $which_files == 3 } {
         FileEntry $w0.filename$i -textvariable initial_highres_files($i) -filetypes IMAGE 
	set pastevar initial_highres_files
    } elseif { $which_files == 4 } {
        FileEntry $w0.filename$i -textvariable highres_files($i) -filetypes IMAGE 
	set pastevar highres_files
    } elseif { $which_files == 20 } {
        FileEntry $w0.filename$i -textvariable confoundev_files($i) -filetypes *
	set pastevar confoundev_files
    }
    $w0.filename$i configure  -label " $i:   " -title "Select input data" -width 60 -filedialog directory
    pack $w0.filename$i -in $w0.f.viewport.f -side top -expand yes -fill both -padx 3 -pady 3
}

#}}}
    #{{{ setup buttons

frame $w0.btns
frame $w0.btns.b -relief raised -borderwidth 1

button $w0.pastebutton -command "feat5:multiple_paste \"Input data\" 1 $fmri(multiple) $pastevar x" -text "Paste"

button $w0.cancel -command "feat5:multiple_check $w $which_files 1 1 d; destroy $w0" -text "OK"

pack $w0.btns.b -side bottom -fill x -padx 3 -pady 5
pack $w0.pastebutton $w0.cancel -in $w0.btns.b -side left -expand yes -padx 3 -pady 3 -fill y
pack $w0.btns -expand yes -fill x

#}}}
}

#}}}
#{{{ feat5:multiple_check

proc feat5:multiple_check { w which_files load updateimageinfo dummy } {
    global FSLDIR fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files confoundev_files
    if { $which_files < 0 } {
	set load 0
	featquery_whichstats $w
    }

    if { $which_files > 2 && $which_files < 20 } {

	if { !$fmri(reg_yn) } {
	    return 0
	}

	set fmri(regstandard) [ remove_ext $fmri(regstandard) ]
	if { [ exec sh -c "${FSLDIR}/bin/fslnvols $fmri(regstandard) 2> /dev/null" ] < 1 } {
	    MxPause "Error: standard-space image
$fmri(regstandard)
is not valid"
	    return 1
	}
	if { $fmri(regstandard_nonlinear_yn) } {
	    set tmpreghead [ stringstrip $fmri(regstandard) _brain ]
	    if { $tmpreghead == $fmri(regstandard) || [ exec sh -c "${FSLDIR}/bin/fslnvols $tmpreghead 2> /dev/null" ] < 1 } {
		MxPause "Warning: nonlinear registration is turned on but FEAT cannot automatically find the whole-head image related to the selected brain-extracted standard-space image
$fmri(regstandard)
(this needs to end in \"_brain\").

If this is not changed, the nonlinear registration will use brain-extracted images instead of whole-head images; this is suboptimal."
	    }
	}
    }

    if { $fmri(multiple) < 2 } {
	set nmultiple 1
    } else {
	set nmultiple $fmri(multiple)
    }

    set AllOK ""

    for { set i 1 } { $i <= $nmultiple } { incr i 1 } {

	if { $which_files == 0 } {

	    if { ! [ info exists feat_files($i) ] } {
		set feat_files($i) ""
	    }

	    if { ! [ file exists $feat_files($i) ] && ! [ imtest $feat_files($i) ] } {
		set AllOK "${AllOK}
Problem with FEAT input file ($i): currently set to \"$feat_files($i)\""
	    } else {
		if { $fmri(level) == 1 && $fmri(analysis) != 4 && $fmri(analysis) != 0 } {
		    set feat_files($i) [ remove_ext $feat_files($i) ]
		    if {  $i == 1 && $updateimageinfo } {
			feat5:updateimageinfo $w $i 1
		    }
		} else {

		    if { $fmri(inputtype) == 1 } {
			if { ! [ file exists $feat_files($i)/design.fsf ] } {
                 	    set AllOK "${AllOK}
Problem with input FEAT directory ($i): currently looking for \"$feat_files($i)/design.fsf\""
			} else {
			    if { $load && $i == 1 && $fmri(level)==1 } {
				feat5:load $w 0 $feat_files(1)/design.fsf
				if { $fmri(level)==2 && $fmri(mixed_yn)==1 } {
				    MxPause "Error: re-running just Post-stats is not possible on existing higher-level FEAT directories that were generated using FLAME 1+2.

To change thresholding, either fully re-run FLAME 1+2 analysis with different Post-stats settings, or fully re-run using FLAME 1, after which it is possible to re-run purely Post-stats."
                 	            set AllOK "${AllOK}
Problem with input FEAT directory ($i) \"$feat_files($i)\""
				} else {
				    MxPause "Warning: have just loaded in design information from the design.fsf
in the first FEAT directory in the list."
				}
			    }
			}
		    }
		}
	    }

	    if { $fmri(level) == 2 && $AllOK == "" } {
		feat5:updateselect $w
	    }

	} elseif { $which_files == 1 } {

	    if { ! [ info exists unwarp_files($i) ] } {
		set unwarp_files($i) ""
	    }

	    set unwarp_files($i) [ remove_ext $unwarp_files($i) ]
	    if { [ exec sh -c "${FSLDIR}/bin/fslnvols $unwarp_files($i) 2> /dev/null" ] < 1 } {
		set AllOK "${AllOK}
Problem with FEAT unwarp file ($i): currently set to \"$unwarp_files($i)\""
	    }

	} elseif { $which_files == 2 } {

	    if { ! [ info exists unwarp_files_mag($i) ] } {
		set unwarp_files_mag($i) ""
	    }
	    
	    set unwarp_files_mag($i) [ remove_ext $unwarp_files_mag($i) ]
	    if { [ exec sh -c "${FSLDIR}/bin/fslnvols $unwarp_files_mag($i) 2> /dev/null" ] < 1 } { 
		set AllOK "${AllOK}
Problem with FEAT unwarp magnitude file ($i): currently set to \"$unwarp_files_mag($i)\""
	    }

	} elseif { $which_files == 3 } {

	    if { ! [ info exists initial_highres_files($i) ] } {
		set initial_highres_files($i) ""
	    }

	    set initial_highres_files($i) [ remove_ext $initial_highres_files($i) ]
	    if { [ exec sh -c "${FSLDIR}/bin/fslnvols $initial_highres_files($i) 2> /dev/null" ] < 1 } {
		set AllOK "${AllOK}
Problem with FEAT initial structural file ($i): currently set to \"$initial_highres_files($i)\""
	    }

	} elseif { $which_files == 4 } {

	    if { ! [ info exists highres_files($i) ] } {
		set highres_files($i) ""
	    }

	    set highres_files($i) [ remove_ext $highres_files($i) ]
	    if { [ exec sh -c "${FSLDIR}/bin/fslnvols $highres_files($i) 2> /dev/null" ] < 1 } {
		set AllOK "${AllOK}
Problem with FEAT main structural file ($i): currently set to \"$highres_files($i)\""
	    }

	    if { $fmri(regstandard_nonlinear_yn) } {
	        set tmpreghead [ stringstrip $highres_files($i) _brain ]
	        if { $tmpreghead == $highres_files($i) || [ exec sh -c "${FSLDIR}/bin/fslnvols $tmpreghead 2> /dev/null" ] < 1 } {
		    MxPause "Warning: nonlinear registration is turned on but FEAT cannot automatically find the whole-head image related to the selected brain-extracted structural image
$highres_files($i)
(this needs to end in \"_brain\").

If this is not changed, the nonlinear registration will use brain-extracted images instead of whole-head images; this is suboptimal."
	        }
	    }

	} elseif { $which_files == 20 } {

	    if { ! [ info exists confoundev_files($i) ] } {
		set confoundev_files($i) ""
	    }

            if { ! [ file exists $confoundev_files($i) ] } {
		set AllOK "${AllOK}
Problem with confound EV file ($i): currently set to \"$confoundev_files($i)\""
            }

	}
    }

    if { $AllOK != "" } {
	MxPause "Error: you haven't filled in all the relevant selections with valid filenames:

$AllOK"
	return 1
    }

    return 0
}

#}}}
#{{{ feat5:multiple_paste

proc feat5:multiple_paste { windowtitle xdim ydim var1name var2 } {
    global FSLDIR
    upvar $var1name var1

    #{{{ setup window

set count 0
set w0 ".dialog[incr count]"
while { [ winfo exists $w0 ] } {
    set w0 ".dialog[incr count]"
}

toplevel $w0

wm iconname $w0 "Paste"
wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm

wm title $w0 "$windowtitle - ${ydim}x$xdim Paste Window"

#}}}
    #{{{ setup main panel

scrollbar $w0.xsbar -command "$w0.text xview" -orient horizontal
scrollbar $w0.ysbar -command "$w0.text yview" -orient vertical

text $w0.text -xscrollcommand "$w0.xsbar set" -yscrollcommand "$w0.ysbar set" \
  -width 60 -height 20 -wrap none 

pack $w0.xsbar -side bottom -fill x
pack $w0.ysbar -side right  -fill y

pack $w0.text -side left -expand yes -fill both

#}}}
    #{{{ setup buttons

frame $w0.buttons

button $w0.buttons.clear -command "$w0.text delete 0.0 end" -text "Clear"

button $w0.buttons.cancel -command "feat5:multiple_paste_process $w0 $xdim $ydim $var1name $var2" -text "OK"

pack $w0.buttons -before $w0.xsbar -side bottom

pack $w0.buttons.clear $w0.buttons.cancel -in $w0.buttons -side left -padx 3 -pady 3

#}}}
    #{{{ fill paste window

    for { set y 1 } { $y <= $ydim } { incr y 1 } {
	for { set x 1 } { $x <= $xdim } { incr x 1 } {
	    if { $var2 == "x" } {
		$w0.text insert end "$var1(${y})"
	    } else {
		$w0.text insert end "$var1(${var2}${y}.${x})\t"
	    }
	}
	$w0.text insert end "\n"
    }

#}}}
}

proc feat5:multiple_paste_process { w0 xdim ydim var1name var2 } {
    upvar $var1name var1

    set alltext [ concat [ $w0.text get 0.0 end ] ]

    if { [ llength $alltext ] < [ expr $xdim * $ydim ] } {
	MxPause "Not enough entries!"
	return 1
    }

    set i 0
    for { set y 1 } { $y <= $ydim } { incr y 1 } {
	for { set x 1 } { $x <= $xdim } { incr x 1 } {
	    if { $var2 == "x" } {
		set var1(${y}) [ lindex $alltext $i ]
	    } else {
		set var1(${var2}${y}.${x}) [ lindex $alltext $i ]
	    }
	    incr i 1
	}
    }

    destroy $w0
}

#}}}
#{{{ feat5:apply

proc feat5:apply { w } {
    global fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FSLDIR HOME

    #{{{ update variables

# not needed with the new non-tix widgets

#foreach v { tr ndelete paradigm_hp brain_thresh smooth uncorrected voxel prob_thresh z_thresh zmin zmax } {
#    $w.$v update
#}

#}}}
    #{{{ write model

if { $fmri(level) > 1 || $fmri(stats_yn) || $fmri(poststats_yn) } {
    set createthemodel 1
} else {
    set createthemodel 0
}

if { $createthemodel == 1 && $fmri(donemodel) == 0 } {
    MxPause "Please setup model before running."
    return 1
}

if { [ feat5:write $w $createthemodel 1 1 $fmri(feat_filename) ] } {
    return 1
}

#}}}
    #{{{ if level>1 test for existing registration

if { $fmri(level) > 1 && $fmri(analysis) != 4 } {

    set problem 0

    for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {

	set featdirname $feat_files($i)
	if { $fmri(inputtype) == 2 } {
	    set featdirname [ file dirname [ file dirname $featdirname ] ]
	}

	if { ! [ file exists $featdirname/reg/example_func2standard.mat ] && 
	     ! [ file exists $featdirname/example_func2standard.mat ] && 
	     ! [ file exists $featdirname/design.lev ] } {
	    set problem 1
	}
    }

    if { $problem } {
	MxPause "Registration has not been run for all of the FEAT directories that you have selected for group analysis.

Please turn on and setup registration."
	return 1
    }

}

#}}}

    set FSFROOT [ file rootname $fmri(feat_filename) ]

    catch { exec sh -c "$FSLDIR/bin/feat $FSFROOT" & } junk

    set fmri(feat_filename) [ exec sh -c "${FSLDIR}/bin/tmpnam /tmp/feat" ].fsf

    update idletasks
}

#}}}
#{{{ feat5:updateanalysis and updatelevel

proc feat5:updatelevel { w } {
    global fmri
   
    if { $fmri(inmelodic) } {
	return 0
    }

    if { $fmri(level) == 1 } {
        $w.mode.analysis.menu entryconfigure 0 -state normal
        $w.mode.analysis.menu entryconfigure 7 -state normal
        $w.mode.analysis.menu entryconfigure 1 -state normal
        $w.mode.analysis.menu entryconfigure 3 -state normal
        $w.mode.analysis.menu entryconfigure 2 -state normal
        $w.mode.analysis.menu entryconfigure 5 -state normal
	set fmri(analysis) 7
	set fmri(reg_yn) 1
	set fmri(r_count) 30
	set fmri(a_count) 30
    } else {
	set fmri(analysis) 6
	set fmri(reg_yn) 0
        $w.mode.analysis.menu entryconfigure 0 -state disabled
        $w.mode.analysis.menu entryconfigure 7 -state disabled
        $w.mode.analysis.menu entryconfigure 1 -state disabled
        $w.mode.analysis.menu entryconfigure 3 -state disabled
        $w.mode.analysis.menu entryconfigure 2 -state disabled
        $w.mode.analysis.menu entryconfigure 5 -state disabled
    }

    feat5:setup_model_vars_simple $w
    set fmri(filmsetup) 0
    feat5:updateanalysis $w
    #Im case model is already open, update to resize altered optionmenus
    #if {[info exists fmri(evsf)]} { $fmri(evsf).evsnb compute_size; $fmri(notebook) compute_size }
}

proc feat5:updateanalysis { w } {
    global fmri

    set fmri(filtering_yn) [ expr   $fmri(analysis)       % 2 == 1 ]
    set fmri(stats_yn)     [ expr ( $fmri(analysis) / 2 ) % 2 == 1 ]
    set fmri(poststats_yn) [ expr ( $fmri(analysis) / 4 ) % 2 == 1 ]

    #{{{ update notebook view

if { !$fmri(filtering_yn) } {
    $w.nb itemconfigure filtering -state disabled
}  else {
    $w.nb itemconfigure filtering -state normal
}

if { !$fmri(stats_yn) } {
    $w.nb itemconfigure stats -state disabled
}  else {
    $w.nb itemconfigure stats -state normal
}

if { !$fmri(poststats_yn) } {
    $w.nb itemconfigure poststats -state disabled
} else {
    $w.nb itemconfigure poststats -state normal
    if { !$fmri(stats_yn) } {
	set fmri(ndelete) 0
    }
}

if { $fmri(level)==1 } {
    $w.nb itemconfigure reg -state normal
}  else {
    $w.nb itemconfigure reg -state disabled
}

#}}}
    #{{{ update misc and data

pack forget $fmri(miscf).newdir_yn
if { $fmri(analysis) == 0 || $fmri(analysis) == 4 } {
    pack $fmri(miscf).newdir_yn -in $fmri(miscf) -anchor w -side top -padx 3 -pady 1
}

pack forget $fmri(contrastest) $fmri(miscf).sscleanup
if { $fmri(inmelodic) == 0 } {
    if { $fmri(level) == 1 } {
	pack $fmri(contrastest) -in $fmri(miscf) -anchor w -side top -padx 3 -pady 1
    } else {
	pack $fmri(miscf).sscleanup -in $fmri(miscf) -anchor w -side top -padx 5 -pady 1
    }
}

if { $fmri(level)==2 && $fmri(analysis)==4 } {
    set fmri(inputtype) 1
}

pack forget $fmri(dataf).inputtype $fmri(dataf).datamain $fmri(dataf).outputdir  
if { $fmri(analysis) != 0 && $fmri(analysis) != 4 } {
    pack $fmri(dataf).outputdir -in $fmri(dataf) -anchor w -side top -pady 10
    if { $fmri(level) == 1  } {
	pack $fmri(dataf).datamain  -in $fmri(dataf) -anchor w -side top -pady 3
    } else {
	pack $fmri(dataf).inputtype -in $fmri(dataf) -before $fmri(dataf).multiple -anchor w -side top -pady 3
    }
}

#}}}

    feat5:updatestats $w 0
    feat5:updatepoststats $w
    feat5:updatereg $w
    feat5:updatemotionevs $w
    $w.nb raise data
}

#}}}
#{{{ feat5:updateselect

proc feat5:updateselect { w } {
    global fmri feat_files

    set fmri(anal_min) 1
    if { ( $fmri(level)==2 && $fmri(analysis)!=4 ) || ( $fmri(inmelodic) && $fmri(icaopt)>1 ) } {
        set fmri(anal_min) 2
	if { $fmri(multiple) < 2 } {
	    set fmri(multiple) 2
	}
    }
    $fmri(dataf).multiple.number configure  -range " $fmri(anal_min) 10000 1 " -validate focusout -vcmd "validNum %W %V %P %s $fmri(anal_min) 10000"
    if { $fmri(level) == 1 && $fmri(analysis) != 4 && $fmri(analysis) != 0 } {
	$fmri(dataf).multiple.setup configure -text "Select 4D data"
    } else {
	if { $fmri(level) == 1 || $fmri(inputtype) == 1 } {
	    if { $fmri(multiple) == 1 } {
		$fmri(dataf).multiple.setup configure -text "Select FEAT directory"
	    } else {
		$fmri(dataf).multiple.setup configure -text "Select FEAT directories"
	    }
	} else {
		$fmri(dataf).multiple.setup configure -text "Select cope images"
	}
    }

    pack forget $fmri(unwarpff).unwarpmultiple $fmri(unwarpff).unwarpsingle $fmri(unwarpff).unwarpmagmultiple $fmri(unwarpff).unwarpmagsingle \
	    $fmri(initial_highresf).initial_highresmultiple $fmri(initial_highresf).initial_highressingle \
	    $fmri(highresf).highresmultiple $fmri(highresf).highressingle

    if { ! $fmri(relative_yn) } {
	if { $fmri(multiple) < 2 } {
	    pack $fmri(unwarpff).unwarpsingle $fmri(unwarpff).unwarpmagsingle -in $fmri(unwarpff) -before $fmri(unwarpff).opts1 -anchor w -side top -pady 2 -padx 3
	    pack $fmri(initial_highresf).initial_highressingle -in $fmri(initial_highresf) -before $fmri(initial_highresf).opts -anchor w -side top -pady 2 -padx 3
	    pack $fmri(highresf).highressingle -in $fmri(highresf) -before $fmri(highresf).opts -anchor w -side top -pady 2 -padx 3
	} else {
	    pack $fmri(unwarpff).unwarpmultiple $fmri(unwarpff).unwarpmagmultiple -in $fmri(unwarpff) -before $fmri(unwarpff).opts1 -anchor w -side top -pady 2 -padx 3
	    pack $fmri(initial_highresf).initial_highresmultiple -in $fmri(initial_highresf) -before $fmri(initial_highresf).opts -anchor w -side top -pady 2 -padx 3
	    pack $fmri(highresf).highresmultiple -in $fmri(highresf) -before $fmri(highresf).opts -anchor w -side top -pady 2 -padx 3
	}
    }

    if { [ winfo exists $w.copeinputs ] } {
	destroy $w.copeinputs
    }
    if { $fmri(level) == 2 &&
	 $fmri(inputtype) == 1 &&
	 $fmri(analysis) != 4 &&
	 [ info exists feat_files(1) ] &&
	 [ file exists $feat_files(1) ] } {
	#{{{ input cope select

frame $w.copeinputs
pack $w.copeinputs -in $fmri(dataf) -before $fmri(dataf).outputdir -side top -anchor w -padx 4 -pady 4

set w0 $w.copeinputs
frame $w0.f
pack $w0.f -expand yes -fill both -in $w0 -side top
canvas $w0.f.viewport -xscrollcommand "$w0.xsbar set" -borderwidth 0
scrollbar $w0.xsbar -command "$w0.f.viewport xview" -orient horizontal
frame $w0.f.viewport.f
$w0.f.viewport create window 0 0 -anchor nw -window $w0.f.viewport.f
bind $w0.f.viewport.f <Configure> "feat5:scrollform_resize $w0 $w0.f.viewport"
pack $w0.f.viewport -side left -fill both -expand true -in $w0.f
set v $w0.f.viewport.f

set statslist [ lsort -dictionary [ imglob $feat_files(1)/stats/cope*.* ] ]
set fmri(ncopeinputs) [ llength $statslist ]
    
if { $fmri(ncopeinputs) < 1 } {
    MxPause "Warning: the first selected FEAT directory contains no stats/cope images"
    return 1
}

label $v.0 -text "Use lower-level copes: "
grid $v.0 -in $v -column 0 -row 0

for { set nci 1 } { $nci <=  $fmri(ncopeinputs) } { incr nci 1 } {   
    if { ! [ info exists fmri(copeinput.$nci) ] } {
	set fmri(copeinput.$nci) 1
    }
    checkbutton $v.$nci -variable fmri(copeinput.$nci) -text "$nci "
    grid $v.$nci -in $v -column $nci -row 0
}
balloonhelp_for $w.copeinputs "The higher-level FEAT analysis will be run separately for each
lower-level contrast. You can tell FEAT to ignore certain lower-level
contrasts by turning off the appropriate button."

#}}}
    }
    if { [ winfo exists $w.nb ] } {
	$w.nb compute_size
    }
}

#}}}
#{{{ feat5:updatehelp

proc feat5:updatehelp { w } {
    global fmri 

    balloonhelp_control $fmri(help_yn)
}

#}}}
#{{{ feat5:updateperfusion

proc feat5:updateperfusion { w } {
    global fmri

    set fmri(templp_yn) 0

    if { ! $fmri(perfsub_yn) } {
        set fmri(prewhiten_yn) 1
        pack forget $fmri(temp).tcmenu
    } else {
        set fmri(prewhiten_yn) 0
        pack $fmri(temp).tcmenu -in $fmri(temp) -after $fmri(temp).ps_yn -side top -side left -padx 5
    }

    if { [ winfo exists $w.nb ] } {
	$w.nb compute_size
    }

    MxPause "Warning - you have changed the \"Perfusion subtraction\" setting, which may have changed the prewhitening option."
}

#}}}
#{{{ feat5:updateprestats

proc feat5:updateprestats { w } {
    global fmri

    if { $fmri(st) < 3 || $fmri(st) > 4 } {
	pack forget $fmri(stf).st_file
    } else {
	pack $fmri(stf).st_file -in $fmri(stf) -side left -padx 5
    }

    if { $fmri(regunwarp_yn) } {
	pack forget $fmri(unwarpf).label 
	pack $fmri(unwarpf).lf -in $fmri(unwarpf) -side left
    } else {
	pack forget $fmri(unwarpf).lf 
	pack $fmri(unwarpf).label -in $fmri(unwarpf) -side left -before $fmri(unwarpf).yn
    }
    if { [ winfo exists $w.nb ] } {
	$w.nb compute_size
    }
}

#}}}
#{{{ feat5:updatemotionevs

proc feat5:updatemotionevs { w } {
    global fmri

    if { ! $fmri(filtering_yn) } {
	set fmri(motionevs) 0
    }

    pack forget $w.confoundevs.enter
    if { $fmri(confoundevs) } {
	pack $w.confoundevs.enter -in $w.confoundevs -after $w.confoundevs.yn -side left -padx 5
    }
}

#}}}
#{{{ feat5:updatestats

proc feat5:updatestats { w process } {
    global fmri

    if { $fmri(inmelodic) } {
	return 0
    }

    if { $process } {
	if { [ info exists fmri(w_model) ] && [ winfo exists $fmri(w_model) ] } {
	    destroy $fmri(w_model)
	}
	feat5:setup_model_vars_simple $w
	if { [ feat5:setup_model_preview $w ] } {
	    return 1
	}
    }
    if { $fmri(infeat) } {
	pack forget $w.prewhiten $w.wizard $w.model $w.mixed $w.motionevs $w.confoundevs $w.robust
	if { $fmri(level) == 1 } {
	    pack $w.prewhiten $w.motionevs $w.confoundevs $w.wizard $w.model -in $fmri(statsf) -anchor w -side top -padx 5 -pady 3
	} else {
	    pack $w.mixed $w.wizard $w.model -in $fmri(statsf) -anchor w -side top -padx 5 -pady 3
	    if { $fmri(mixed_yn) != 3 } {
		pack $w.robust -in $fmri(statsf) -after $w.mixed -anchor w -side top -padx 5 -pady 3
	    }
	}
    } else {
	glm:updatelevel $w
    }
}

#}}}
#{{{ feat5:updatepoststats

proc feat5:updatepoststats { w } {
    global fmri

    if { $fmri(inmelodic) } {
	return 0
    }

    pack forget $w.modelcon $w.z_thresh $w.prob_thresh $w.conmask $w.render $w.bgimage $w.zmin $w.zmax

    if { ! $fmri(stats_yn) } {
	pack $w.modelcon -in $fmri(poststatsf) -before $fmri(poststatsf).threshmask -side top -anchor w -padx 5 -pady 5
    }

    if { $fmri(thresh) } {
	if { $fmri(thresh) == 1 } {
            $w.prob_thresh configure -label "Uncorrected voxel P threshold"
	} elseif { $fmri(thresh) == 2 } {
	    $w.prob_thresh configure -label "Corrected voxel P threshold"
	} else {
	    $w.prob_thresh configure -label "Cluster P threshold"
             pack $w.z_thresh -in $fmri(lfthresh) -side left -anchor w -pady 2
	}
        pack $w.prob_thresh -in $fmri(lfthresh) -side left


	pack $w.conmask -in $fmri(poststatsf) -after $w.thresh -side top -anchor w -pady 5 -padx 5
	pack $w.render  -in $fmri(poststatsf) -after $w.conmask -side top -anchor w -pady 5

	pack $fmri(lfrenderingtop) -in $fmri(lfrendering) -anchor w -padx 3 -pady 3

	if { $fmri(level) > 1 } {
	    pack $w.bgimage -in $fmri(lfrendering) -before $fmri(lfrenderingtop) -anchor w -padx 3 -pady 3
	}
	
	if { $fmri(zdisplay) } {
	    pack $w.zmin $w.zmax -in $fmri(lfrenderingtop) -after $w.zmaxmenu -side left -anchor n -padx 3 -pady 5
	}
    }

    $w.nb compute_size
}

#}}}
#{{{ feat5:updatereg

proc feat5:updatereg_hr_init { w } {
    global fmri

    if { $fmri(reginitial_highres_yn) == 1 } {
	set fmri(reghighres_yn) 1
    }

    feat5:updatereg $w
}

proc feat5:updatereg_hr { w } {
    global fmri

    if { $fmri(reghighres_yn) == 0 } {
	set fmri(reginitial_highres_yn) 0
    }

    feat5:updatereg $w
}

proc feat5:updatereg { w } {
    global fmri

    if { $fmri(inmelodic) && $fmri(icaopt)>1 } {
	set fmri(regstandard_yn) 1
    }

    if { ! $fmri(regstandard_nonlinear_yn) } {
	pack forget $fmri(standardf).nlopts.nonlinear_warpres
    } else {
	pack $fmri(standardf).nlopts.nonlinear_warpres -in $fmri(standardf).nlopts -side left
	if { $fmri(regstandard_yn) } {
	    set fmri(reghighres_yn) 1
	}
    }

    if { $fmri(regreduce_dof) > 0 } {
	set fmri(reginitial_highres_dof) 3
	set fmri(reghighres_dof) 6
	set fmri(regstandard_dof) 12

	set thedof 7
	if { $fmri(regreduce_dof) == 2 } {
	    set thedof 3
	}

	if { $fmri(reginitial_highres_yn) } {
	    set fmri(reginitial_highres_dof) $thedof
	} elseif { $fmri(reghighres_yn) } {
	    set fmri(reghighres_dof) $thedof
	} elseif { $fmri(regstandard_yn) } {
	    set fmri(regstandard_dof) $thedof
	}
    }

    if { $fmri(reginitial_highres_yn) } {
	pack forget $fmri(regf).initial_highres.label 
	pack $fmri(regf).initial_highres.lf -in $fmri(regf).initial_highres -side left
    } else {
	pack forget $fmri(regf).initial_highres.lf 
	pack $fmri(regf).initial_highres.label -in $fmri(regf).initial_highres -side left
    }

    if { $fmri(reghighres_yn) } {
	pack forget $fmri(regf).highres.label 
	pack $fmri(regf).highres.lf -in $fmri(regf).highres -side left
    } else {
	pack forget $fmri(regf).highres.lf 
	pack $fmri(regf).highres.label -in $fmri(regf).highres -side left
    }

    if { $fmri(regstandard_yn) } {
	pack forget $fmri(regf).standard.label 
	pack $fmri(regf).standard.lf -in $fmri(regf).standard -side left
    } else {
	pack forget $fmri(regf).standard.lf 
	pack $fmri(regf).standard.label -in $fmri(regf).standard -side left
    }

    feat5:updateselect $w
}

#}}}
#{{{ feat5:updateimageinfo

proc feat5:updateimageinfo { w i full } {
    global FSLDIR feat_files fmri

    set thefile [ remove_ext $feat_files($i) ]

    set changed_stuff 0

    if { [ imtest $thefile ] } {
	set feat_files($i) $thefile
	set npts [ exec sh -c "${FSLDIR}/bin/fslnvols $thefile 2> /dev/null" ]

	if { $npts > 0 } {
	    set fmri(npts) $npts
	}

	if { $full } {

	    # set BET and FLIRT DOF according to FOV
	    set xfov [ expr abs([ exec sh -c "$FSLDIR/bin/fslval $thefile pixdim1" ] * [ exec sh -c "$FSLDIR/bin/fslval $thefile dim1" ]) ]
	    set yfov [ expr abs([ exec sh -c "$FSLDIR/bin/fslval $thefile pixdim2" ] * [ exec sh -c "$FSLDIR/bin/fslval $thefile dim2" ]) ]
	    set zfov [ expr abs([ exec sh -c "$FSLDIR/bin/fslval $thefile pixdim3" ] * [ exec sh -c "$FSLDIR/bin/fslval $thefile dim3" ]) ]
	    
	    set BETMINFOV 30
	    if { $xfov < $BETMINFOV || $yfov < $BETMINFOV || $zfov < $BETMINFOV } {
		set fmri(bet_yn) 0
		set changed_stuff 1
	    }

	    set fmri(regreduce_dof) 0

	    set REGMINFOV 120
	    if { $xfov < $REGMINFOV || $yfov < $REGMINFOV || $zfov < $REGMINFOV } {
		set fmri(regreduce_dof) 1
		feat5:updatereg $w
		set changed_stuff 1
	    }

	    set REGTRANSMINFOV 60
	    if { $xfov < $REGTRANSMINFOV || $yfov < $REGTRANSMINFOV || $zfov < $REGTRANSMINFOV } {
		set fmri(regreduce_dof) 2
		feat5:updatereg $w
		set changed_stuff 1
	    }

	    if { $changed_stuff } {
		MxPause "Warning - have auto-set BET preprocessing option and/or registration DoF on the basis of image fields-of-view; check settings."
	    }
	}
    }

    if { $fmri(level) > 1 && $fmri(analysis) != 4 } {
	set fmri(npts) $fmri(multiple)
    }
}

#}}}
#{{{ feat5:estnoise

proc feat5:estnoise { } {

    global fmri feat_files FSLDIR

    set smooth [ expr $fmri(smooth) / 2.355 ]

    set hp_sigma_vol -1
    if { $fmri(temphp_yn) } {
	set hp_sigma_sec [ expr $fmri(paradigm_hp) / 2.0 ]
	set hp_sigma_vol [ expr $hp_sigma_sec / $fmri(tr) ]
    }

    set lp_sigma_vol -1
    if { $fmri(templp_yn) } {
	set lp_sigma_sec 2.8
	set lp_sigma_vol [ expr $lp_sigma_sec / $fmri(tr) ]
    }

    if { [ info exists feat_files(1) ] && [ imtest $feat_files(1) ] } {
	set noiseestout [ exec sh -c "${FSLDIR}/bin/estnoise $feat_files(1) $smooth $hp_sigma_vol $lp_sigma_vol 2> /dev/null" ]
	set fmri(noise)   [ lindex $noiseestout 0 ]
	set fmri(noisear) [ lindex $noiseestout 1 ]
    }
}

#}}}
#{{{ feat5:wizard

proc feat5:wizard { w } {
    global FSLDIR fmri

    #{{{ setup window

    set count 0
    set w0 ".dialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".dialog[incr count]"
    }

    toplevel $w0

    wm title $w0 "Model setup wizard"
    wm iconname $w0 "wizard"
    wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm

    frame $w0.f
    pack $w0.f

#}}}

    if { $fmri(level) == 1 } {
	#{{{ choose paradigm type

frame $w0.f.paradigm_type

set fmri(wizard_type) 1	

radiobutton $w0.f.paradigm_type.jab -text "rArA..." -value 1 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
radiobutton $w0.f.paradigm_type.jabac -text "rArBrArB..." -value 2 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
radiobutton $w0.f.paradigm_type.jperfab -text "perfusion rArA..." -value 3 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
balloonhelp_for $w0.f.paradigm_type "Choose whether to setup rArA... or rArBrArB... designs (regular block
or single-event). The r blocks will normally be rest (or control)
conditions.

The \"perfusion rArA...\" option sets up the full model for a simple
perfusion experiment, setting up a constant-height control-tag EV, an
average BOLD component EV and the interaction EV, which represents the
control-tag functional modulation."

pack $w0.f.paradigm_type.jab $w0.f.paradigm_type.jabac $w0.f.paradigm_type.jperfab -in $w0.f.paradigm_type -side top -padx 5 -side left

#}}}
	#{{{ frame ab

frame $w0.f.ab

set fmri(r_count) 30
LabelSpinBox  $w0.f.ab.r_count -label "r (rest) period (s)" -textvariable fmri(r_count) -range {0.0 10000 1 } 
set fmri(a_count) 30
LabelSpinBox  $w0.f.ab.a_count -label "A period (s)" -textvariable fmri(a_count) -range {0.0 10000 1 } 
set fmri(b_count) 30
LabelSpinBox $w0.f.ab.b_count -label "B period (s)" -textvariable fmri(b_count) -range {0.0 10000 1 }

pack $w0.f.ab.r_count $w0.f.ab.a_count -in $w0.f.ab -side left -padx 5 -pady 3 -anchor n
balloonhelp_for $w0.f.ab.r_count "The r period (seconds) is normally the rest period, i.e., no
stimulation was applied during this period."
balloonhelp_for $w0.f.ab.a_count "The A period (seconds) is normally the activation period, i.e.,
stimulation was applied during this period."
balloonhelp_for $w0.f.ab.b_count "The B period (seconds) is normally the period associated with a second
type of activation, i.e., stimulation type 2 was applied during this
period."

#}}}
    } else {
	#{{{ choose paradigm type

frame $w0.f.paradigm_type

set fmri(wizard_type) 1	

radiobutton $w0.f.paradigm_type.onegroup -text "single group average" -value 1 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
radiobutton $w0.f.paradigm_type.twogroupunpaired -text "two groups, unpaired" -value 2 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
radiobutton $w0.f.paradigm_type.twogrouppaired -text "two groups, paired" -value 3 -variable fmri(wizard_type) -command "feat5:update_wizard $w0"
balloonhelp_for $w0.f.paradigm_type "Select from the different higher-level designs. In the case of the
unpaired two-group test, set the number of subjects in the first
group. Note that in the case of the paired two-group test, your
subjects should be entered: first all subjects for the first
condition, then all the subjects (in the same order) for the second
condition."

pack $w0.f.paradigm_type.onegroup $w0.f.paradigm_type.twogroupunpaired $w0.f.paradigm_type.twogrouppaired -in $w0.f.paradigm_type -side top -padx 3 -anchor w

#}}}
	#{{{ frame ab

frame $w0.f.ab
LabelSpinBox $w0.f.ab.a_count -label "Number of subjects in first group" -textvariable fmri(a_count) -range "1 [ expr $fmri(multiple) - 1 ] 1 " 
balloonhelp_for $w0.f.ab.a_count "This is the number of subjects in the first group of subjects. The
number of subjects in the second group is calculated automatically."

#}}}
    }
    #{{{ setup button

button $w0.f.cancel -command "feat5:updatestats $w 1 ; destroy $w0" -text "Process"

#}}}
 
    pack $w0.f.paradigm_type $w0.f.ab $w0.f.cancel -in $w0.f -pady 5
}

#{{{ feat5:update_wizard

proc feat5:update_wizard { w } {
    global fmri

    if { $fmri(level) == 1 } {
	if { $fmri(wizard_type) == 2 } {
	    set fmri(r_count) 30
	    set fmri(a_count) 30
	    set fmri(b_count) 30
	    pack $w.f.ab.b_count -in $w.f.ab -after $w.f.ab.a_count -side left -padx 5 -pady 3 -anchor n
	} else {
	    set fmri(r_count) 30
	    set fmri(a_count) 30
	    pack forget $w.f.ab.b_count
	}
    } else {
	pack forget $w.f.ab.a_count
	if { $fmri(wizard_type) == 2 } {
	    set fmri(a_count) 1
	    pack $w.f.ab.a_count -in $w.f.ab -side left -padx 5 -pady 3 -anchor n
	}
    }
}

#}}}

#}}}
#{{{ feat5:setup_model

proc feat5:setup_model { w } {
    global FSLDIR fmri VARS PWD

    #{{{ setup window

    if { [ info exists fmri(w_model) ] } {
	if { [ winfo exists $fmri(w_model) ] } {
	    return 0
	}
    }

    set count 0
    set w0 ".wdialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".wdialog[incr count]"
    }

    set fmri(w_model) $w0

    toplevel $w0

    wm title $w0 "General Linear Model"
    wm iconname $w0 "GLM"
    wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm

    frame $w0.f
    pack $w0.f -expand yes -fill both -in $w0 -side top

    canvas $w0.f.viewport -yscrollcommand "$w0.f.ysbar set" -xscrollcommand "$w0.xsbar set"
    scrollbar $w0.xsbar -command "$w0.f.viewport xview" -orient horizontal
    scrollbar $w0.f.ysbar -command "$w0.f.viewport yview" -orient vertical
    frame $w0.f.viewport.f
    $w0.f.viewport create window 0 0 -anchor nw -window $w0.f.viewport.f
    bind $w0.f.viewport.f <Configure> "feat5:scrollform_resize $w0 $w0.f.viewport"
    pack $w0.f.viewport -side left -fill both -expand true -in $w0.f

    set fmri(notebook) [NoteBook $w0.f.viewport.f.nb  -side top -bd 2 -tabpady {5 10} -arcradius 3 ]
    if { $fmri(analysis) != 4 } {
    $w0.f.viewport.f.nb insert 0 evs -text "EVs"    
    }
    $w0.f.viewport.f.nb insert 1 contrasts     -text "Contrasts & F-tests"
    pack  $w0.f.viewport.f.nb -in $w0.f.viewport.f -expand true -fill both

#}}}
    #{{{ setup contrasts & F-tests

set fmri(contrastsf) [  $w0.f.viewport.f.nb getframe contrasts ]
frame $fmri(contrastsf).men
if { $fmri(level) == 1 } {
label  $fmri(contrastsf).label -text "Setup contrasts & F-tests for "

    optionMenu2 $fmri(contrastsf).con_men fmri(con_mode) -command "feat5:setup_model_update_contrasts_mode $w 1;feat5:setup_model_update_contrasts $w" orig "Original EVs" real "Real EVs"
pack  $fmri(contrastsf).label $fmri(contrastsf).con_men -in $fmri(contrastsf).men -side left -anchor w -padx 5 -pady 0 
balloonhelp_for $fmri(contrastsf).con_men "For first-level analyses, it is common for the final design matrix to
have a greater number of \"real EVs\" than the \"original\" number; for
example, when using basis functions, each \"original EV\" gives rise
to several \"real EVs\".

Therefore it is possible it many cases for you to setup contrasts and
F-tests with respect to the \"original EVs\", and FEAT will work out
for you what these will be for the final design matrix. For example, a
single \[1\] contrast on an original EV for which basis function HRF
convolutions have been chosen will result in a single \[1\] contrast
for each resulting real EV, and then an F-test across these.

In general you can switch between setting up contrasts and F-tests
with respect to \"Original EVs\" and \"Real EVs\"; though of course if
you fine-tune the contrasts for real EVs and then revert to original
EV setup some settings may be lost.

When you \"View\" the design matrix or press \"Done\" at the end of
setting up the model, an \"Original EVs\" setup will get converted to
the appropriate \"Real EVs\" settings."
}



frame $fmri(contrastsf).num

LabelSpinBox  $fmri(contrastsf).num.con -label "Contrasts " -textvariable fmri(ncon_$fmri(con_mode)) -range {1 10000 1 }  -modifycmd "feat5:setup_model_update_contrasts $w" -command "$fmri(contrastsf).num.con.spin.e validate;feat5:setup_model_update_contrasts $w" 
LabelSpinBox  $fmri(contrastsf).num.ftests -label "   F-tests " -textvariable fmri(nftests_$fmri(con_mode)) -range {0 10000 1 }  -modifycmd "feat5:setup_model_update_contrasts $w" -command "$fmri(contrastsf).num.ftests.spin.e validate;feat5:setup_model_update_contrasts $w" 

pack $fmri(contrastsf).num.con $fmri(contrastsf).num.ftests -in $fmri(contrastsf).num -side left -anchor n -padx 5 -pady 0
pack $fmri(contrastsf).men $fmri(contrastsf).num -in $fmri(contrastsf) -side top -anchor w -padx 0 -pady 5

feat5:setup_model_update_contrasts $w

balloonhelp_for $fmri(contrastsf).num.con "Each EV (explanatory variable, i.e., waveform) in the design matrix
results in a PE (parameter estimate) image.  This estimate tells you
how strongly that waveform fits the data at each voxel - the higher it
is, the better the fit. For an unblurred square wave input (which will
be scaled in the model from -0.5 to 0.5), the PE image is equivalent to
the \"mean difference image\". To convert from a PE to a t
statistic image, the PE is divided by it's standard error, which is
derived from the residual noise after the complete model has been
fit. The t image is then transformed into a Z statistic via standard
statistical transformation. As well as Z images arising from single
EVs, it is possible to combine different EVs (waveforms) - for
example, to see where one has a bigger effect than another. To do
this, one PE is subtracted from another, a combined standard error is
calculated, and a new Z image is created.

All of the above is controlled by you, by setting up contrasts. Each
output Z statistic image is generated by setting up a contrast vector;
thus set the number of outputs that you want, using \"Number of
contrasts\". To convert a single EV into a Z statistic image, set it's
contrast value to 1 and all others to 0. Thus the simplest design,
with one EV only, has just one contrast vector, and only one entry in
this contrast vector; 1. To add more contrast vectors, increase the
\"Number of contrasts\". To compare two EVs, for example, to subtract
one stimulus type (EV1) from another type (EV2), set EV1's contrast
value to -1 and EV2's to 1. A Z statistic image will be generated
according to this request."

balloonhelp_for $fmri(contrastsf).num.ftests "F-tests enable you to investigate several contrasts at the same time,
for example to see whether any of them (or any combination of them) is
significantly non-zero. Also, the F-test allows you to compare the
contribution of each contrast to the model and decide on significant
and non-significant ones.

One example of F-test usage is if a particular stimulation is to be
represented by several EVs, each with the same input function
(e.g. square wave or custom timing) but all with different HRF
convolutions - i.e. several \"basis functions\". Putting all relevant
resulting parameter estimates together into an F-test allows the
complete fit to be tested against zero without having to specify the
relative weights of the basis functions (as one would need to do with
a single contrast). So - if you had three basis functions (EVs 1,2 and
3) the wrong way of combining them is a single (T-test) contrast of
\[1 1 1\]. The right way is to make three contrasts \[1 0 0\] \[0 1 0\] and
\[0 0 1\] and enter all three contrasts into an F-test. As
described above, FEAT will automatically do this for you if you set up
contrasts for \"original EVs\" instead of \"real EVs\".

You can carry out as many F-tests as you like. Each test includes the
particular contrasts that you specify by clicking on the appropriate
buttons."

#}}}
    #{{{ setup EVs

if { $fmri(analysis) != 4 } {

    set fmri(evsf) [$w0.f.viewport.f.nb getframe evs ]

    if { $fmri(level) == 1 } {
	set ev_description " original"
    } else {
	set ev_description " main"
    }

    LabelSpinBox $fmri(evsf).evs -label " Number of$ev_description EVs " -textvariable fmri(evs_orig) -range {1 10000 1 } -modifycmd "feat5:setup_model_update_evs $w $fmri(evsf) 1" -command "$fmri(evsf).evs.spin.e validate; feat5:setup_model_update_evs $w $fmri(evsf) 1 "  

balloonhelp_for $fmri(evsf).evs "The basic number of explanatory variables in the design matrix; this
means the number of different effects that you wish to model - one for
each modelled stimulation type, and one for each modelled confound.

For first-level analyses, it is common for the final design matrix to
have a greater number of \"real EVs\" than this \"original\" number; for
example, when using basis functions, each \"original EV\" gives rise
to several \"real EVs\"."
    pack $fmri(evsf).evs -in $fmri(evsf) -padx 2 -pady 2 -side top -anchor w

    if { $fmri(level) > 1 } {
	LabelSpinBox $fmri(evsf).voxevs -label " Number of additional, voxel-dependent EVs " -textvariable fmri(evs_vox) -range {0 10000 1 } -modifycmd "feat5:setup_model_update_evs $w $fmri(evsf) 1" -command "$fmri(evsf).voxevs.spin.e validate; feat5:setup_model_update_evs $w $fmri(evsf) 1 "  
	balloonhelp_for $fmri(evsf).voxevs "This allows you to add voxel-dependent EVs; every voxel will have a
different higher-level model. For each additional EV that you ask for,
you will need to provide the filename of a 4D image file whose first 3
dimensions are the size of standard space, and whose 4th dimension
corresponds to the number of sessions/subjects that you are inputting
into this higher-level analysis.

A typical use of voxel-dependent EVs would be to insert grey-matter
partial volume information on the basis of structural imaging.

Note that when you use this option and view the design matrix, a
voxel-dependent EV is respresented graphically by the mean EV across
all voxels, which may well not be very meaningful.

If you want to use structural images (as used in the first-level FEAT
registrations) to create the covariates, then you can easily generate
the 4D covariate image with the \"feat_gm_prepare\" script; just type
the script name followed by the desired 4D output image name and then
the full list of first-level FEAT directories (these must be in the
same order as they will appear as inputs to the higher-level FEAT
analysis). You should run this script after all the first-level FEAT
analyses and before running the higher-level FEAT."
	pack $fmri(evsf).voxevs -in $fmri(evsf) -padx 2 -pady 2 -side top -anchor w
    }

    if { $fmri(level) == 1 } {
        NoteBook $fmri(evsf).evsnb -side top -bd 2 -tabpady {5 10} -arcradius 3 
        pack $fmri(evsf).evsnb -in $fmri(evsf) -padx 2 -pady 2 -side top -anchor w -expand true -fill both
    }
    feat5:setup_model_update_evs $w $fmri(evsf) 1

} else {
    feat5:setup_model_update_evs $w 0 0
}

#}}}
    #{{{ setup buttons

frame $w0.btns
pack $w0.btns -padx 2 -pady 2 -in $w0 -side bottom

frame $w0.btns.b -relief raised -borderwidth 2
pack $w0.btns.b -in $w0.btns -side bottom -fill x -padx 2 -pady 2

button $w0.btns.b.view -command "feat5:setup_model_preview $w" -text "View design"
balloonhelp_for $w0.btns.b.view $fmri(design_help)

set fmri(cov_help) "This is a graphical representation of the covariance of the design matrix and the efficiency of the design/contrasts. Of most practical importance are the values in the lower part of the window, showing the estimability of the contrasts.


The first matrix shows the absolute value of the normalised correlation of each EV with each EV. If a design is well-conditioned (i.e. not approaching rank deficiency) then the diagonal elements should be white and all others darker.

So - if there are any very bright elements off the diagonal, you can immediately tell which EVs are too similar to each other - for example, if element \[1,3\] (and \[3,1\]) is bright then columns 1 and 3 in the design matrix are possibly too similar.

Note that this includes all real EVs, including any added temporal derivatives, basis functions, etc.

The second matrix shows a similar thing after the design matrix has been run through SVD (singular value decomposition). All non-diagonal elements will be zero and the diagonal elements are given by the eigenvalues of the SVD, so that a poorly-conditioned design is obvious if any of the diagonal elements are black.


In the lower part of the window, for each requested contrast, that contrast's efficiency/estimability is shown. This is formulated as the strength of the signal required in order to detect a statistically significant result for this contrast. For example, in FMRI data and with a single regressor, this shows the BOLD % signal change required. In the case of a differential contrast, it shows the required difference in BOLD signal between conditions.

This \"Effect Required\" depends on the design matrix, the contrast values, the statistical significance level chosen, and the noise level in the data (see the \"Misc\" tab in the main FEAT GUI). The lower the effect required, the more easily estimable is a contrast, i.e. the more efficient is the design.

Note that this does not tell you everything that there is to know about paradigm optimisation. For example, all things being equal, event-related designs tend to give a smaller BOLD effect than block designs - the efficiency estimation made here cannot take that kind of effect into account!"

button $w0.btns.b.acview -command "feat5:setup_model_acpreview $w" -text "Efficiency"
balloonhelp_for $w0.btns.b.acview $fmri(cov_help)

button $w0.btns.b.cancel -command "feat5:setup_model_destroy $w $w0" -text "Done"
pack $w0.btns.b.view $w0.btns.b.acview -in $w0.btns.b -side left -expand yes -padx 3 -pady 3 -fill y
if { $fmri(infeat) } {
    pack $w0.btns.b.cancel -in $w0.btns.b -side left -expand yes -padx 3 -pady 3 -fill y
}

set a [eval {$w0.f.viewport.f.nb pages 0}]
$w0.f.viewport.f.nb raise $a
if {$a == "evs" && $fmri(level) == 1} {
$fmri(evsf).evsnb raise ev1
}

#}}}
}

#{{{ feat5:setup_model_vars_simple

proc feat5:setup_model_vars_simple { w } {
    global fmri

    set fmri(filmsetup) 1

    if { $fmri(level) == 1 } {

	set fmri(con_mode) orig
	set fmri(con_mode_old) orig

	if { $fmri(wizard_type) == 1 } {
	    #{{{ setup wizard type 1

	set fmri(evs_orig) 1
	set fmri(evs_real) 2

	set fmri(evtitle1) ""
	set fmri(shape1) 0
	set fmri(skip1) 0
	set fmri(off1) $fmri(r_count)
	set fmri(on1) $fmri(a_count)
	set fmri(phase1) 0
	set fmri(stop1) -1

	set fmri(convolve1) $fmri(default_convolve)
	set fmri(convolve_phase1) $fmri(default_convolve_phase)
	set fmri(gammasigma1) $fmri(default_gammasigma)
	set fmri(gammadelay1) $fmri(default_gammadelay)
	set fmri(tempfilt_yn1) 1
	set fmri(deriv_yn1) $fmri(default_deriv_yn)

	set fmri(ortho1.0) 0
	set fmri(ortho1.1) 0

	set fmri(ncon_orig) 1
	set fmri(con_orig1.1) 1
	set fmri(conpic_orig.1) 1
	set fmri(conname_orig.1) ""

	set fmri(nftests_orig) 0

	set fmri(paradigm_hp) [ expr $fmri(r_count) + $fmri(a_count) ]

#}}}   
	} elseif { $fmri(wizard_type) == 2 } {
	    #{{{ setup wizard type 2

	set fmri(evs_orig) 2
	set fmri(evs_real) 4

	set fmri(evtitle1) "A"
	set fmri(evtitle2) "B"
	set fmri(shape1) 0
	set fmri(shape2) 0
	set fmri(skip1) 0
	set fmri(skip2) 0
	set fmri(off1) [ expr $fmri(r_count) * 2 + $fmri(b_count) ]
	set fmri(on1) $fmri(a_count)
	set fmri(off2) [ expr $fmri(r_count) * 2 + $fmri(a_count) ]
	set fmri(on2) $fmri(b_count)
	set fmri(phase1) [ expr $fmri(r_count) + $fmri(b_count) ]
	set fmri(phase2) 0
	set fmri(stop1) -1
	set fmri(stop2) -1
	set fmri(convolve1) $fmri(default_convolve)
	set fmri(convolve2) $fmri(default_convolve)
	set fmri(convolve_phase1) $fmri(default_convolve_phase)
	set fmri(convolve_phase2) $fmri(default_convolve_phase)
	set fmri(gammasigma1) $fmri(default_gammasigma)
	set fmri(gammasigma2) $fmri(default_gammasigma)
	set fmri(gammadelay1) $fmri(default_gammadelay)
	set fmri(gammadelay2) $fmri(default_gammadelay)
	set fmri(tempfilt_yn1) 1
	set fmri(tempfilt_yn2) 1
	set fmri(deriv_yn1) $fmri(default_deriv_yn)
	set fmri(deriv_yn2) $fmri(default_deriv_yn)

	set fmri(ortho1.0) 0
	set fmri(ortho1.1) 0
	set fmri(ortho1.2) 0
	set fmri(ortho2.0) 0
	set fmri(ortho2.1) 0
	set fmri(ortho2.2) 0
	
	set fmri(ncon_orig) 4
	set fmri(con_orig1.1) 1
	set fmri(con_orig1.2) 0
	set fmri(con_orig2.1) 0
	set fmri(con_orig2.2) 1
	set fmri(con_orig3.1) 1
	set fmri(con_orig3.2) -1
	set fmri(con_orig4.1) -1
	set fmri(con_orig4.2) 1

	set fmri(conpic_orig.1) 1
	set fmri(conpic_orig.2) 1
	set fmri(conpic_orig.3) 1
	set fmri(conpic_orig.4) 1

	set fmri(conname_orig.1) "A"
	set fmri(conname_orig.2) "B"
	set fmri(conname_orig.3) "A>B"
	set fmri(conname_orig.4) "B>A"

	set fmri(nftests_orig) 1
	set fmri(ftest_orig1.1) 1
	set fmri(ftest_orig1.2) 1
	set fmri(ftest_orig1.3) 0
	set fmri(ftest_orig1.4) 0

	set fmri(paradigm_hp) [ expr  ( 2 * $fmri(r_count) ) + $fmri(a_count) + $fmri(b_count) ]

#}}}
	} else {
	    #{{{ setup wizard type 3

	set fmri(evs_orig) 3
	set fmri(evs_real) 3

	set fmri(evtitle1) "c-t"
	set fmri(evtitle2) "BOLD"
	set fmri(evtitle3) "c-t act"
	set fmri(shape1) 0
	set fmri(shape2) 0
	set fmri(shape3) 4
	set fmri(skip1) 0
	set fmri(skip2) 0
	set fmri(off1) $fmri(tr)
	set fmri(on1) $fmri(tr)
	set fmri(off2) $fmri(r_count)
	set fmri(on2) $fmri(a_count)
	set fmri(phase1) 0
	set fmri(phase2) 0
	set fmri(stop1) -1
	set fmri(stop2) -1
	set fmri(convolve1) 0
	set fmri(convolve2) $fmri(default_convolve)
	set fmri(convolve3) 0
	set fmri(convolve_phase2) $fmri(default_convolve_phase)
	set fmri(convolve_phase3) 0
	set fmri(gammasigma2) $fmri(default_gammasigma)
	set fmri(gammadelay2) $fmri(default_gammadelay)

        set fmri(interactions3.1) 1
        set fmri(interactionsd3.1) 1
        set fmri(interactions3.2) 1
        set fmri(interactionsd3.2) 0

	set fmri(tempfilt_yn1) 1
	set fmri(tempfilt_yn2) 1
	set fmri(tempfilt_yn3) 1
	set fmri(deriv_yn1) 0
	set fmri(deriv_yn2) 0
	set fmri(deriv_yn3) 0

	set fmri(ortho1.0) 0
	set fmri(ortho1.1) 0
	set fmri(ortho1.2) 0
	set fmri(ortho1.3) 0
	set fmri(ortho2.0) 0
	set fmri(ortho2.1) 0
	set fmri(ortho2.2) 0
	set fmri(ortho2.3) 0
	set fmri(ortho3.0) 0
	set fmri(ortho3.1) 0
	set fmri(ortho3.2) 0
	set fmri(ortho3.3) 0
	
	set fmri(ncon_orig) 6
	set fmri(con_orig1.1) 0
	set fmri(con_orig1.2) 0
	set fmri(con_orig1.3) 1
	set fmri(con_orig2.1) 0
	set fmri(con_orig2.2) 0
	set fmri(con_orig2.3) -1
	set fmri(con_orig3.1) 0
	set fmri(con_orig3.2) 1
	set fmri(con_orig3.3) 0
	set fmri(con_orig4.1) 0
	set fmri(con_orig4.2) -1
	set fmri(con_orig4.3) 0
	set fmri(con_orig5.1) 1
	set fmri(con_orig5.2) 0
	set fmri(con_orig5.3) 0
	set fmri(con_orig6.1) -1
	set fmri(con_orig6.2) 0
	set fmri(con_orig6.3) 0

	set fmri(conpic_orig.1) 1
	set fmri(conpic_orig.2) 1
	set fmri(conpic_orig.3) 1
	set fmri(conpic_orig.4) 1
	set fmri(conpic_orig.5) 1
	set fmri(conpic_orig.6) 1

	set fmri(conname_orig.1) "perfusion activation"
	set fmri(conname_orig.2) "-perfusion activation"
	set fmri(conname_orig.3) "BOLD"
	set fmri(conname_orig.4) "-BOLD"
	set fmri(conname_orig.5) "control-tag baseline"
	set fmri(conname_orig.6) "control-tag -baseline"

	set fmri(nftests_orig) 0

	set fmri(paradigm_hp) [ expr $fmri(r_count) + $fmri(a_count) ]

#}}}
	}

    } else {

	set fmri(tr) 3

	if { $fmri(wizard_type) == 1 } {
	    #{{{ setup higher-level starting values

set fmri(evs_orig) 1
set fmri(evs_real) 1

set fmri(custom1) dummy
set fmri(shape1) 2
set fmri(convolve1)    0    
set fmri(tempfilt_yn1) 0
set fmri(deriv_yn1)    0
set fmri(ortho1.0)     0
for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
    set fmri(evg${i}.1) 1
    set fmri(groupmem.${i}) 1
}


set fmri(ncon_real) 1
set fmri(con_mode) real
set fmri(con_mode_old) real
set fmri(con_real1.1) 1
set fmri(conpic_real.1) 1
set fmri(nftests_real) 0
set fmri(conname_real.1) "group mean"

#}}}
	} elseif { $fmri(wizard_type) == 2 } {
	    #{{{ setup higher-level starting values
set fmri(evs_orig) 2
set fmri(evs_real) 2

set fmri(evtitle1) "group A"
set fmri(evtitle2) "group B"
set fmri(custom1) dummy
set fmri(custom2) dummy
set fmri(shape1) 2
set fmri(shape2) 2
set fmri(convolve1) 0    
set fmri(convolve2) 0    
set fmri(convolve_phase1) 0    
set fmri(convolve_phase2) 0    
set fmri(tempfilt_yn1) 0
set fmri(tempfilt_yn2) 0
set fmri(deriv_yn1) 0
set fmri(deriv_yn2) 0
set fmri(ortho1.0) 0
set fmri(ortho1.1) 0
set fmri(ortho1.2) 0
set fmri(ortho2.0) 0
set fmri(ortho2.1) 0
set fmri(ortho2.2) 0
for { set i 1 } { $i <=  $fmri(multiple) } { incr i 1 } {
    if { $i <= $fmri(a_count) } {
	set fmri(evg${i}.1) 1
	set fmri(evg${i}.2) 0
	set fmri(groupmem.${i}) 1
    } else {
	set fmri(evg${i}.1) 0
	set fmri(evg${i}.2) 1
	set fmri(groupmem.${i}) 2
    }
}

set fmri(ncon_real) 4
set fmri(con_mode) real
set fmri(con_mode_old) real
set fmri(conpic_real.1) 1
set fmri(conpic_real.2) 1
set fmri(conpic_real.3) 1
set fmri(conpic_real.4) 1
set fmri(con_real1.1) 1
set fmri(con_real1.2) -1
set fmri(con_real2.1) -1
set fmri(con_real2.2) 1
set fmri(con_real3.1) 1
set fmri(con_real3.2) 0
set fmri(con_real4.1) 0
set fmri(con_real4.2) 1
set fmri(conname_real.1) "group A > group B"
set fmri(conname_real.2) "group B > group A"
set fmri(conname_real.3) "group A mean"
set fmri(conname_real.4) "group B mean"
set fmri(nftests_real) 0

#}}}
	} else {
	    #{{{ setup higher-level starting values
set nsubjects [ expr $fmri(multiple) / 2 ]

set fmri(evs_orig) [ expr $nsubjects + 1 ]
set fmri(evs_real) $fmri(evs_orig)

for { set i 1 } { $i <=  $fmri(evs_orig) } { incr i 1 } {
    set fmri(custom${i}) dummy
    set fmri(shape${i}) 2
    set fmri(convolve${i}) 0    
    set fmri(convolve_phase${i}) 0    
    set fmri(tempfilt_yn${i}) 0
    set fmri(deriv_yn${i}) 0
    set fmri(evtitle${i}) "s[ expr $i - 1 ]"
    for { set j 0 } { $j <=  $fmri(evs_orig) } { incr j 1 } {
	set fmri(ortho${i}.${j}) 0
    }
}

set fmri(evtitle1) "A > B"

for { set i 1 } { $i <=  $fmri(multiple) } { incr i 1 } {
    set fmri(groupmem.${i}) 1

    if { $i <= $nsubjects } {
	set fmri(evg${i}.1) 1
    } else {
	set fmri(evg${i}.1) -1
    }

    for { set j 2 } { $j <= $fmri(evs_orig) } { incr j 1 } {
	set fmri(evg${i}.${j}) 0	
    }
}

for { set i 1 } { $i <= $nsubjects } { incr i 1 } {
    set fmri(evg${i}.[ expr 1 + $i ]) 1
    set fmri(evg[ expr $i + $nsubjects ].[ expr 1 + $i ]) 1
}

set fmri(ncon_real) 2
set fmri(con_mode) real
set fmri(con_mode_old) real
set fmri(conpic_real.1) 1
set fmri(conpic_real.2) 1

set fmri(con_real1.1) 1
set fmri(con_real2.1) -1
for { set i 2 } { $i <= $fmri(evs_orig) } { incr i 1 } {
    set fmri(con_real1.${i}) 0
    set fmri(con_real2.${i}) 0
}

set fmri(conname_real.1) "condition A > B"
set fmri(conname_real.2) "condition B > A"
set fmri(nftests_real) 0

#}}}
	}
    }
}

#}}}
#{{{ feat5:setup_model_update_ev_i

proc feat5:setup_model_update_ev_i { w w0 i whocalled resize} {
    global fmri

    #whocalled: misc=0 shape-change=1 convolve-change=2

    if { $fmri(level)==1 } {

	#{{{ basic shape/timings stuff

pack forget $w0.evsnb.skip$i $w0.evsnb.off$i $w0.evsnb.on$i $w0.evsnb.phase$i $w0.evsnb.stop$i $w0.evsnb.period$i $w0.evsnb.nharmonics$i $w0.evsnb.custom$i $w0.evsnb.interaction$i

if { $fmri(shape$i) == 0 } {

    pack $w0.evsnb.skip$i $w0.evsnb.off$i $w0.evsnb.on$i $w0.evsnb.phase$i $w0.evsnb.stop$i -in $w0.evsnb.timings$i -padx 5 -pady 2 -side top -anchor w

} elseif { $fmri(shape$i) == 1 } {

    pack $w0.evsnb.skip$i $w0.evsnb.period$i $w0.evsnb.phase$i $w0.evsnb.nharmonics$i $w0.evsnb.stop$i -in $w0.evsnb.timings$i -padx 5 -pady 2 -side top -anchor w

} elseif { $fmri(shape$i) == 2 || $fmri(shape$i) == 3 } {

    pack $w0.evsnb.custom$i -in $w0.evsnb.timings$i -padx 5 -pady 2 -side top -anchor w

} elseif { $fmri(shape$i) == 4 } {

    pack $w0.evsnb.interaction$i -in $w0.evsnb.timings$i -padx 5 -pady 2 -side top -anchor w
    set selected 0
    for { set j 1 } { $j < $i } { incr j 1 } {
	set selected [ expr $selected + $fmri(interactions${i}.$j) ]
    }
    if { $selected < 2 } {
	if { !$fmri(interactions${i}.1) } {
	    set fmri(interactions${i}.1) 1
	} else {
	    set fmri(interactions${i}.2) 1
	}
    }

}

if { $whocalled == 1 } {

    if { $fmri(shape$i) == 1 } {
	set fmri(phase$i) -6
    } else {
	set fmri(phase$i) 0
    }

    set fmri(convolve$i) $fmri(default_convolve)
    set fmri(tempfilt_yn$i) 1
}

#}}}

	if { $fmri(shape$i) != 1 && $fmri(shape$i) != 4 && $fmri(shape$i) != 10 } {

	    pack $w0.evsnb.conv$i -in $fmri(modelf$i) -after $w0.evsnb.timings$i -padx 5 -pady 2 -side top -anchor w
	    pack forget $w0.evsnb.convolve_phase$i $w0.evsnb.gausssigma$i $w0.evsnb.gaussdelay$i \
		$w0.evsnb.gammasigma$i $w0.evsnb.gammadelay$i $w0.evsnb.bfcustom$i $w0.evsnb.bfcustomlabel$i \
		$w0.evsnb.basisfnum$i $w0.evsnb.basisfwidth$i $w0.evsnb.basisorth$i
	    if { $fmri(convolve$i) > 0 } {
		pack $w0.evsnb.convolve_phase$i -in $w0.evsnb.conv$i -padx 5 -pady 2 -side top -anchor w
		if { $fmri(convolve$i) == 1 } {
		    pack $w0.evsnb.gausssigma$i $w0.evsnb.gaussdelay$i -in $w0.evsnb.conv$i -padx 5 -pady 2 -side top -anchor w
		} elseif { $fmri(convolve$i) == 2 } {
		    pack $w0.evsnb.gammasigma$i $w0.evsnb.gammadelay$i -in $w0.evsnb.conv$i -padx 5 -pady 2 -side top -anchor w
		} elseif { $fmri(convolve$i) > 3 && $fmri(convolve$i) < 7 } {
		    pack $w0.evsnb.basisfnum$i $w0.evsnb.basisfwidth$i $w0.evsnb.basisorth$i -in $w0.evsnb.conv$i -padx 5 -pady 2 -side top -anchor w
		    if { $whocalled == 2 || ! [ info exists fmri(basisorth$i) ] } {
			set fmri(basisorth$i) 0
		    }
		} elseif { $fmri(convolve$i) == 7 } {
		    pack $w0.evsnb.bfcustom$i $w0.evsnb.bfcustomlabel$i $w0.evsnb.basisorth$i -in $w0.evsnb.conv$i -padx 5 -pady 2 -side top -anchor w
		    if { $whocalled == 2 || ! [ info exists fmri(basisorth$i) ] } {
			set fmri(basisorth$i) 1
		    }
		}
	    }
	} else {
	    pack forget $w0.evsnb.conv$i
	    set fmri(convolve$i) 0
	}

	#{{{ tempfilt

if { $fmri(shape$i) != 10 } {
    pack $w0.evsnb.tempfilt$i -in $fmri(modelf$i) -padx 5 -pady 2 -side bottom -anchor w
} else { 
    pack forget $w0.evsnb.tempfilt$i
}

#}}}

	#{{{ orthogonalise

if { $fmri(evs_orig) > 1 && $fmri(shape$i) != 10 } {

    if { ! [ winfo exists $w0.evsnb.ortho$i ] } {

	frame $w0.evsnb.ortho$i

	checkbutton $w0.evsnb.ortho$i.0 -variable fmri(ortho${i}.0) \
		-command "feat5:setup_model_update_ev_i $w $w0 $i 0 1"

	pack $w0.evsnb.ortho$i.0 -in $w0.evsnb.ortho$i -side left
        balloonhelp_for $w0.evsnb.ortho$i "Orthogonalising an EV with respect to other EVs means that it is
completely independent of the other EVs, i.e. contains no component
related to them. Most sensible designs are already in this form - all
EVs are at least close to being orthogonal to all others. However,
this may not be the case; you can use this facility to force an EV to
be orthogonal to some or all other EVs. This is achieved by
subtracting from the EV that part which is related to the other EVs
selected here.

An example use would be if you had another EV which was a
constant height spike train, and the current EV is derived from this
other one, but with a linear increase in spike height imposed, to
model an increase in response during the experiment for any
reason. You would not want the current EV to contain any component of
the constant height EV, so you would orthogonalise the current EV wrt
the other."

        pack $w0.evsnb.ortho$i -in $fmri(modelf$i) -after $w0.evsnb.tempfilt$i -padx 5 -pady 2 -side top -anchor w
    }

    for { set j 1 } { $j > 0 } { incr j 1 } {
	if { [ winfo exists $w0.evsnb.ortho$i.$j ] } {
	    destroy $w0.evsnb.ortho$i.$j
	} elseif { $j != $i } {
	    set j -10
	}
    }

    if { $fmri(ortho${i}.0) == 1 } {
	$w0.evsnb.ortho$i.0 configure -text "Orthogonalise    wrt EVs "
	for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
	    if { $j != $i } {
		checkbutton $w0.evsnb.ortho$i.$j -text "$j " -variable fmri(ortho${i}.$j)
		pack $w0.evsnb.ortho$i.$j -in $w0.evsnb.ortho$i -side left -padx 0
	    }
	}
    } else {
	$w0.evsnb.ortho$i.0 configure -text "Orthogonalise"
    }

} else {

    if { [ winfo exists $w0.evsnb.ortho$i ] } {
	destroy $w0.evsnb.ortho$i $w0.evsnb.ortho$i.0
	set fmri(ortho${i}.0) 0
    }
}

#}}}

	#{{{ deriv

if { ( $fmri(shape$i) != 1 && $fmri(convolve$i) < 4 ) || $fmri(shape$i) == 10 } {
    pack $w0.evsnb.deriv$i -in $fmri(modelf$i) -padx 5 -pady 2 -side bottom -anchor w
} else { 
    set fmri(deriv_yn$i) 0
    pack forget $w0.evsnb.deriv$i
}

#}}}
    }
    feat5:setup_model_update_contrasts $w 

    if {$resize != 0} {
	$w0.evsnb compute_size
	$fmri(notebook) compute_size
    }
}

#}}}
#{{{ feat5:setup_model_update_evs

proc feat5:setup_model_update_evs { w w0 update_gui } {
    global fmri PWD tempSpin

    #{{{ initialise variables

    for { set i 1 } { $i <= $fmri(evs_orig) } { incr i 1 } {

	for { set j 0 } { $j <= $fmri(evs_orig) } { incr j 1 } {
	    if { ! [ info exists fmri(ortho${i}.$j) ] } {
		set fmri(ortho${i}.$j) 0
	    }
	}

	if { $fmri(level) == 1 } {
	    #{{{ initialise variables

if { ! [ info exists fmri(evtitle$i) ] } {
    set fmri(evtitle$i) ""
}

if { ! [ info exists fmri(shape$i) ] } {
    set fmri(shape$i) 0
}

if { ! [ info exists fmri(skip$i) ] } {
    set fmri(skip$i) 0
}

if { ! [ info exists fmri(off$i) ] } {
    set fmri(off$i) 30
}

if { ! [ info exists fmri(on$i) ] } {
    set fmri(on$i) 30
}

if { ! [ info exists fmri(phase$i) ] } {
    set fmri(phase$i) 0
}

if { ! [ info exists fmri(stop$i) ] } {
    set fmri(stop$i) -1
}

if { ! [ info exists fmri(period$i) ] } {
    set fmri(period$i) 60
}

if { ! [ info exists fmri(nharmonics$i) ] } {
    set fmri(nharmonics$i) 0
}

if { ! [ info exists fmri(convolve$i) ] } {
    set fmri(convolve$i) $fmri(default_convolve)
}

if { ! [ info exists fmri(convolve_phase$i) ] } {
    set fmri(convolve_phase$i) $fmri(default_convolve_phase)
}

if { ! [ info exists fmri(gausssigma$i) ] } {
    set fmri(gausssigma$i) $fmri(default_gausssigma)
}

if { ! [ info exists fmri(gaussdelay$i) ] } {
    set fmri(gaussdelay$i) $fmri(default_gaussdelay)
}

if { ! [ info exists fmri(gammasigma$i) ] } {
    set fmri(gammasigma$i) $fmri(default_gammasigma)
}

if { ! [ info exists fmri(gammadelay$i) ] } {
    set fmri(gammadelay$i) $fmri(default_gammadelay)
}

if { ! [ info exists fmri(bfcustom$i) ] } {
    set fmri(bfcustom$i) $fmri(default_bfcustom) 
}

if { ! [ info exists fmri(basisfnum$i) ] } {
    set fmri(basisfnum$i) 3
}

if { ! [ info exists fmri(basisfwidth$i) ] } {
    set fmri(basisfwidth$i) 15
}

if { ! [ info exists fmri(tempfilt_yn$i) ] } {
    set fmri(tempfilt_yn$i) 1
}

if { ! [ info exists fmri(deriv_yn$i) ] } {
    set fmri(deriv_yn$i) $fmri(default_deriv_yn)
}

if { ! [ info exists fmri(interactions${i}.1) ] && $i > 2 } {
    for { set j 1 } { $j < $i } { incr j 1 } {
	if { $j < 3 } {
	    set fmri(interactions${i}.$j) 1
	} else {
	    set fmri(interactions${i}.$j) 0
	}
	set fmri(interactionsd${i}.$j) 0
    }
}

#}}}
	} else {
	    set fmri(custom$i) dummy
	    set fmri(shape$i) 2
	    set fmri(convolve$i) 0    
	    set fmri(convolve_phase$i) 0
	    set fmri(tempfilt_yn$i) 0
	    set fmri(deriv_yn$i) 0
	    for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
		if { ! [ info exists fmri(evg$i.$j) ] } {
		    set fmri(evg$i.$j) 0
		}
	    }
	}
    }

#}}}

    if { $update_gui } {

	if { $fmri(level) == 1 } {
	    #{{{ setup EV notebook for level=1

	for { set i 1 } { $i > 0 } { incr i 1 } {
	    if { $i <= $fmri(evs_orig) } {

		if { ! [ info exists fmri(modelf$i) ] || ! [ winfo exists $fmri(modelf$i) ] } {
		    #{{{ setup EV tab i

$w0.evsnb insert $i ev$i -text "$i"
set fmri(modelf$i) [ $w0.evsnb getframe ev$i ]

#{{{ EV name

frame $w0.evsnb.evtitle$i

label $w0.evsnb.evtitle${i}.label -text "EV name "

entry $w0.evsnb.evtitle${i}.entry -textvariable fmri(evtitle$i) -width 7
balloonhelp_for $w0.evsnb.evtitle$i "If you wish, enter a title for EV $i here."

pack $w0.evsnb.evtitle${i}.label $w0.evsnb.evtitle${i}.entry -in $w0.evsnb.evtitle$i -side left

#}}}

#{{{ basic shape

set grot $fmri(shape$i)

frame $w0.evsnb.shapemenu$i
label $w0.evsnb.label$i -text "Basic shape: "
if { $i > 2 } {
    optionMenu2 $w0.evsnb.shape$i fmri(shape$i) -command "feat5:setup_model_update_ev_i $w $w0 $i 1 1" 10 "Empty (all zeros)" 0 "Square" 1 "Sinusoid" 2 "Custom (1 entry per volume)" 3 "Custom (3 column format)" 4 "Interaction"
} else {
    optionMenu2 $w0.evsnb.shape$i fmri(shape$i) -command "feat5:setup_model_update_ev_i $w $w0 $i 1 1" 10 "Empty (all zeros)" 0 "Square" 1 "Sinusoid" 2 "Custom (1 entry per volume)" 3 "Custom (3 column format)"
}
pack  $w0.evsnb.label$i $w0.evsnb.shape$i -in $w0.evsnb.shapemenu$i -side left 

set fmri(shape$i) $grot
balloonhelp_for $w0.evsnb.shape$i "Choose the basic shape of the waveform that describes the stimulus or confound that you wish to model. The basic waveform should be exactly in time with the applied stimulation, i.e., not lagged at all. This is because the measured (time-series) response will be delayed with respect to the stimulation, and this delay is modelled in the design matrix by convolution of the basic waveform with a suitable haemodynamic response function (see appropriate bubble-help).

If you need an EV to be ignored, choose \"Empty (all zeros)\". You are most likely to want to do this if you want the EVs to all have the same meaning for multiple runs, but in some runs one or more EVs contain no events of the relevant type. Note that in this case you will get a warning about the matrix being rank deficient.

For an on/off (or a regularly-spaced single-event) experiment choose a \"square\" wave. To model single-event experiments with this method, the \"On\" periods will probably be small - e.g., 1s or even less.

For sinusoidal modelling choose the \"Sinusoid\" option and select the number of \"Harmonics\" (or overtones) that you want to add to the fundamental frequency.

For a single-event experiment with irregular timing for the stimulations, a custom file can be used. With \"Custom (1 entry per volume)\", you specify a single value for each timepoint. The custom file should be a raw text file, and should be a list of numbers, separated by spaces or newlines, with one number for each volume (after subtracting the number of deleted images). These numbers can either all be 0s and 1s, or can take a range of values. The former case would be appropriate if the same stimulus was applied at varying time points; the latter would be appropriate, for example, if recorded subject responses are to be inserted as an effect to be modelled. Note that it may or may not be appropriate to convolve this particular waveform with an HRF - in the case of single-event, it is.

For even finer control over the input waveform, choose \"Custom (3 column format)\". In this case the custom file consists of triplets of numbers; you can have any number of triplets. Each triplet describes a short period of time and the value of the model during that time. The first number in each triplet is the onset (in seconds) of the period, the second number is the duration (in seconds) of the period, and the third number is the value of the input during that period. The same comments as above apply, about whether these numbers are 0s and 1s, or vary continuously. The start of the first non-deleted volume correpsonds to t=0.

Note that whilst ALL columns are demeaned before model fitting, neither custom format will get rescaled - it is up to you to make sure that relative scaling between different EVs is sensible. If you double the scaling of values in an EV you will halve the resulting parameter estimate, which will change contrasts of this EV against others.

If you select \"Interaction\" then the current EV is modelled as an interaction between other EVs, and is normally used to create a third EV from two existing EVs, to model the nonlinear interaction between two different conditions (or for a Psycho-Physiological Interaction, or PPI, analysis). On the line of buttons marked \"Between EVs\" you select which other EVs to interact to form the new one. The selected EVs then get multiplied together to form the current EV. Normally they are multiplied after (temporarily) shifting their values so that the minimum of each EV is zero (\"Make zero = Min\"); however, if you change the \"Make zero:\" option, individual EVs will instead be zero-centred about the min and max values (\"Centre\") or de-meaned (\"Mean\"). If all EVs feeding into an interaction have the same convolution settings, the interaction is calculated before convolutions, and the same convolution applied to the interaction; if they do not all have the same settings, then all convolutions are applied before forming the interaction, and no further convolution is applied to the interaction EV.

For PPI analyses, you should probably do something like: Set EV1 to your main effect of interest, set EV2 to your data-derived regressor (with convolution turned off for EV2), and set EV3 to be an \"Interaction\". EV3 would then be an interaction between EV1 and EV2, with EV1's zeroing set to \"Centre\" and EV2's zeroing set to \"Mean\"."

#}}}
#{{{ timings / custom name

frame $w0.evsnb.timings$i
option add *evsnb.LabelSpinBox*labf*width 15
LabelSpinBox $w0.evsnb.skip$i -textvariable fmri(skip$i) -label "    Skip (s)" -range {0.0 10000 1 } 
balloonhelp_for $w0.evsnb.skip$i "The initial period (seconds) before the waveform commences."

LabelSpinBox $w0.evsnb.off$i -textvariable fmri(off$i) -label "    Off (s)" -range {0.0 10000 1 }
balloonhelp_for $w0.evsnb.off$i "The duration (seconds) of the \"Off\" periods in the square wave."

LabelSpinBox $w0.evsnb.on$i -textvariable fmri(on$i) -label "    On (s)" -range {0.0 10000 1 } 
balloonhelp_for $w0.evsnb.on$i "The duration (seconds) of the \"On\" periods in the square wave."

LabelSpinBox $w0.evsnb.phase$i -textvariable fmri(phase$i) -label "    Phase (s)" -range {-10000.0 10000 1 }
balloonhelp_for $w0.evsnb.phase$i "The phase shift (seconds) of the waveform. By default, after the \"Skip\" period, the square wave\nstarts with a full \"Off\" period and the \"Sinusoid\" starts by falling from zero. However, the\nwave can be brought forward in time according to the phase shift."

LabelSpinBox $w0.evsnb.stop$i -textvariable fmri(stop$i) -label "    Stop after (s)" -range {-1.0 10000 1 } 
balloonhelp_for $w0.evsnb.stop$i "The active duration (seconds) of the waveform, starting\nafter the \"Skip\" period. \"-1\" means do not stop."

LabelSpinBox $w0.evsnb.period$i -textvariable fmri(period$i) -label "    Period (s)"  -range {0.1 10000 1 } 
balloonhelp_for $w0.evsnb.period$i "The period (seconds) of the \"Sinusoid\" waveform."

LabelSpinBox $w0.evsnb.nharmonics$i -textvariable fmri(nharmonics$i) -label "    Harmonics"  -range {0 10000 1 }  -modifycmd "feat5:setup_model_update_contrasts $w" -command " $w0.evsnb.nharmonics$i validate; feat5:setup_model_update_contrasts $w" 
balloonhelp_for $w0.evsnb.nharmonics$i "How many harmonics (sine waves with periods of half the primary sine
wave, then quarter, etc) would you like?"

FileEntry  $w0.evsnb.custom$i -textvariable fmri(custom$i) -label "    Filename" -title "Select an event file" -width 30 -filedialog directory  -filetypes * 

if { $i > 2 } {
    frame $w0.evsnb.interaction$i
    label $w0.evsnb.interaction$i.label -text "Between EVs "
    label $w0.evsnb.interaction$i.labeld -text "Make zero: "
    grid $w0.evsnb.interaction$i.label -in $w0.evsnb.interaction$i -column 0 -row 0
    grid $w0.evsnb.interaction$i.labeld -in $w0.evsnb.interaction$i -column 0 -row 1
    for { set j 1 } { $j < $i } { incr j 1 } {
	checkbutton $w0.evsnb.interaction$i.$j -variable fmri(interactions${i}.$j) -text "$j " -command "feat5:setup_model_update_ev_i $w $w0 $i 0 1"
	grid $w0.evsnb.interaction$i.$j -in $w0.evsnb.interaction$i -column $j -row 0
	#checkbutton $w0.evsnb.interaction$i.d$j -variable fmri(interactionsd${i}.$j) -text "$j "
	optionMenu2 $w0.evsnb.interaction$i.d$j fmri(interactionsd${i}.$j) 0 "Min" 1 "Centre" 2 "Mean"
	grid $w0.evsnb.interaction$i.d$j -in $w0.evsnb.interaction$i -column $j -row 1
    }
}

#}}}

#{{{ convolution

frame $w0.evsnb.conv$i

frame $w0.evsnb.convmenu$i 
pack forget  $w0.evsnb.labelconv$i $w0.evsnb.convolve$i $w0.evsnb.convmenu$i
label $w0.evsnb.labelconv$i -text "Convolution: "
optionMenu2 $w0.evsnb.convolve$i fmri(convolve$i) -command  "feat5:setup_model_update_ev_i $w $w0 $i 2 1" 0 "None" 1 "Gaussian" 2 "Gamma" 3 "Double-Gamma HRF" 7 "Optimal/custom basis functions" 4 "Gamma basis functions" 5 "Sine basis functions" 6 "FIR basis functions"
pack $w0.evsnb.labelconv$i $w0.evsnb.convolve$i -in $w0.evsnb.convmenu$i -side left 
pack $w0.evsnb.convmenu$i -in $w0.evsnb.conv$i -padx 0 -pady 2 -side top -anchor w 

balloonhelp_for $w0.evsnb.convolve$i "The form of the HRF (haemodynamic response function) convolution that
will be applied to the basic waveform. This blurs and delays the
original waveform, in an attempt to match the difference between the
input function (original waveform, i.e., stimulus waveform) and the
output function (measured FMRI haemodynamic response). 

If the original waveform is already in an appropriate form, e.g., was
sampled from the data itself, \"None\" should be selected.

The next three options are all somewhat similar blurring and delaying
functions. \"Gaussian\" is simply a Gaussian kernel, whose width and
lag can be altered. \"Gamma\" is a Gamma variate (in fact a
normalisation of the probability density function of the Gamma
function); again, width and lag can be altered. \"Double-Gamma HRF\" is a
preset function which is a mixture of two Gamma functions - a standard
positive function at normal lag, and a small, delayed, inverted Gamma,
which attempts to model the late undershoot. 

The remaining convolution options setup different \"basis
functions\". This means that the original EV waveform will get
convolved by a \"basis set\" of related but different convolution
kernels. By default, an \"original EV\" will generate a set of \"real
EVs\", one for each basis function.

The \"Optimal/custom\" option allows you to use a customised set of
basis functions, setup in a plain text file with one column for each
basis function, sampled at the temporal resolution of 0.05s. The main
point of this option is to allow the use of \"FLOBS\" (FMRIB's Linear
Optimal Basis Set), which is a method for generating a set of basis
functions that has optimal efficiency in covering the range of likely
HRF shapes actually found in your data. You can either use the default
FLOBS set, or use the \"Make_flobs\" GUI on the FEAT \"Utils\" menu to
create your own customised set of FLOBS.

The other basis function options, which will not in general be as good
at fitting the data as FLOBS, are a set of \"Gamma\" variates of
different widths and lags, a set of \"Sine\" waves of differing
frequencies or a set of \"FIR\" (finite-impulse-response) filters
(with FIR the convolution kernel is represented as a set of discrete
fixed-width \"impulses\").

For all basis function options there is the option to force exact
orthogonalisation of the functions with respect to each other. For
basis functions which are generally expected to be orthogonal
(normally just) the \"Optimal/custom\" option) this option should
normally be left on, otherwise you would normally expect to leave it
turned off."

#}}}
#{{{ convolution parameters

LabelSpinBox  $w0.evsnb.convolve_phase$i -textvariable fmri(convolve_phase$i) -label "    Phase (s)"  -range {-10000.0 10000 1 } 
balloonhelp_for $w0.evsnb.convolve_phase$i "This sets the \"Phase\" of the convolution - i.e. phase shifts the
convolved time series. Positive values shift the final time series
earlier in time."
LabelSpinBox  $w0.evsnb.gausssigma$i -textvariable fmri(gausssigma$i) -label "    Sigma (s)" -range {0.01 10000 0.1 }
balloonhelp_for $w0.evsnb.gausssigma$i "This sets the half-width of the Gaussian smoothing of the input waveform."
LabelSpinBox  $w0.evsnb.gaussdelay$i -textvariable fmri(gaussdelay$i) -label "    Peak lag (s)" -range {0.01 10000 0.1 }  
balloonhelp_for $w0.evsnb.gaussdelay$i "This sets the peak lag of the Gaussian smoothing of the input waveform."
LabelSpinBox  $w0.evsnb.gammasigma$i -textvariable fmri(gammasigma$i) -label "    Stddev (s)" -range {0.01 10000 0.1 } 
balloonhelp_for $w0.evsnb.gammasigma$i "This sets the half-width of the Gamma smoothing of the input waveform."
LabelSpinBox  $w0.evsnb.gammadelay$i -textvariable fmri(gammadelay$i) -label "    Mean lag (s)" -range {0.01 10000 0.1 }  
balloonhelp_for $w0.evsnb.gammadelay$i "This sets the mean lag of the Gamma smoothing of the input waveform."

FileEntry $w0.evsnb.bfcustom$i -textvariable fmri(bfcustom$i) -label "    Filename" -title "Select a custom HRF convolution file" -width 30 -filedialog directory  -filetypes * -command "feat5:checkbfcustom $w $i dummy; feat5:setup_model_update_contrasts $w"

label $w0.evsnb.bfcustomlabel$i -text "      (create a custom optimal basis set with Utils->Make_flobs)"

frame $w0.evsnb.basisorth$i
label $w0.evsnb.basisorth${i}.label -text "    Orthogonalise basis functions wrt each other"
checkbutton $w0.evsnb.basisorth${i}.cb -variable fmri(basisorth$i)
pack $w0.evsnb.basisorth${i}.label $w0.evsnb.basisorth${i}.cb -in $w0.evsnb.basisorth$i -padx 0 -pady 2 -side left

LabelSpinBox  $w0.evsnb.basisfnum$i -textvariable fmri(basisfnum$i) -label "    Number" -range {1 10000 1 }  -command "$w0.evsnb.basisfnum$i.spin.e validate;feat5:setup_model_update_contrasts $w" -modifycmd "feat5:setup_model_update_contrasts $w" 
balloonhelp_for $w0.evsnb.basisfnum$i "This sets the number of basis functions."
LabelSpinBox  $w0.evsnb.basisfwidth$i -textvariable fmri(basisfwidth$i) -label "    Window (s)" -range {1.0 10000 1 } 
balloonhelp_for $w0.evsnb.basisfwidth$i "This sets the total period over which the basis functions are spread."

#}}}

#{{{ temporal filtering

checkbutton $w0.evsnb.tempfilt$i -variable fmri(tempfilt_yn$i) -text "Apply temporal filtering" 
balloonhelp_for $w0.evsnb.tempfilt$i "You should normally apply the same temporal filtering to the model as
you have applied to the data, as the model is designed to look like
the data before temporal filtering was applied. Thus long-time-scale
components in the model will be dealt with correctly."

#}}}
#{{{ temporal derivative

checkbutton $w0.evsnb.deriv$i -variable fmri(deriv_yn$i) -text "Add temporal derivative" \
	-command "feat5:setup_model_update_contrasts $w"
balloonhelp_for $w0.evsnb.deriv$i "Adding a fraction of the temporal derivative of the blurred original
waveform is equivalent to shifting the waveform slightly in time, in
order to achieve a slightly better fit to the data. Thus adding in the
temporal derivative of a waveform into the design matrix allows a
better fit for the whole model, reducing unexplained noise, and
increasing resulting statistical significances. This option is not
available if you are using basis functions."

#}}}

pack $w0.evsnb.evtitle$i  $w0.evsnb.shapemenu$i $w0.evsnb.timings$i $w0.evsnb.tempfilt$i -in $fmri(modelf$i) -padx 5 -pady 2 -side top -anchor w

#}}}
		} else {
		    $w0.evsnb itemconfigure ev$i -state normal
		}

		feat5:setup_model_update_ev_i $w $w0 $i 0 0

	    } else {
		#{{{ disable nb page

		if { [ info exists fmri(modelf$i) ] && [ winfo exists $fmri(modelf$i) ] } {
		    $w0.evsnb itemconfigure ev$i -state disabled
		} else {
		    set i -10
		}

#}}}
	    }
	}

#}}}
	} else {
	    #{{{ EV grid for level>1

set w1 $fmri(evsf).grid
if { [ winfo exists $w1 ] } {
    destroy $w1
}
frame $w1
pack $w1 -in $fmri(evsf) -side top -anchor w -padx 5 -pady 5

button $w1.pastebutton -command "feat5:multiple_paste \"Higher-level model EVs\" $fmri(evs_orig) $fmri(multiple) fmri evg" -text "Paste"
grid $w1.pastebutton -in $w1 -row 0 -column 0

label $w1.grouplabel -text "     Group     "
grid $w1.grouplabel -in $w1 -row 0 -column 1

for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
    label $w1.evlabel${j} -text "EV$j"
    grid $w1.evlabel${j} -in $w1 -row 0 -column [ expr $j + 1 ]
    entry $w1.evtitle${j} -textvariable fmri(evtitle$j) -width 7
    grid $w1.evtitle${j} -in $w1 -row 1 -column [ expr $j + 1 ] -padx 2 -pady 2
    balloonhelp_for $w1.evtitle${j} "If you wish, enter a title for EV $j here."
}

for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {

    label $w1.label$i -text "Input $i "
    grid $w1.label$i -in $w1 -row [ expr $i + 1 ] -column 0
    balloonhelp_for $w1.label$i "Input (lower-level FEAT directory) ${i}."

    if { ! [ info exists fmri(groupmem.$i) ] } {
	set fmri(groupmem.$i) 1
    }
    SpinBox   $w1.groupmem$i -textvariable fmri(groupmem.$i) -range {0 10000 1 } -width 3
    grid $w1.groupmem$i -in $w1 -row [ expr $i + 1 ] -column 1
    balloonhelp_for $w1.groupmem$i "Which group of subjects (or sessions, etc.) is this input a part of?

If you setup different groups for different variances, you will get
fewer data-points to estimate each variance (than if only one variance
was estimated). Therefore, you only want to use this option if you do
believe that the groups possibly do have different variances.

If you setup different groups for different variances, it is necessary
that, for each EV, only one of the sub-groups has non-zero
values. Thus, for example, in the case of an unpaired t-test:

GP EV1 EV2
1   1    1 
1   1    1 
1   1    1 
1   1    1 
2   1   -1
2   1   -1
2   1   -1

is wrong with respect to this issue, and the following is correct:

GP EV1 EV2
1   1    0 
1   1    0 
1   1    0 
1   1    0 
2   0    1
2   0    1
2   0    1

Note that if you are using this to create input files for randomise then the 
group numbers are use to specify exchangeability blocks, where randomise 
permutes within blocks. A 0 is used to specify a static (unpermuted) block"

    for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
        SpinBox   $w1.evg${i}_${j} -textvariable fmri(evg${i}.${j}) -width 3 
        $w1.evg${i}_${j} configure  -range {-10000.0 10000 1 } -validate focusout -vcmd  {validNum %W %V %P %s [lindex [[string range %W 0 end-2] cget -range] 0] [lindex [[string range %W 0 end-2] cget -range] 1]} -invcmd { set [%W cget -textvariable] $tempSpin; %W config -validate %v } 
        #need to do configure after declaration to get new Inputs initialising to 0 (could also put new init in to setup_var)... 
	grid $w1.evg${i}_${j} -in $w1 -row [ expr $i + 1 ] -column [ expr $j + 1 ]
        balloonhelp_for $w1.evg${i}_${j} "Design matrix value for Input (lower-level FEAT directory) $i and EV ${j}."
    }
}

if { [ winfo exists $fmri(evsf).orthbutton ] } {
    destroy $fmri(evsf).orthbutton
}
if { $fmri(evs_orig) > 1 } {
    if { ! [ info exists fmri(level2orth) ] || ! $fmri(level2orth) } {
	button $fmri(evsf).orthbutton -command "feat5:setup_level2orth $w $w1;$fmri(notebook) compute_size" -text "Setup orthogonalisations"
	pack $fmri(evsf).orthbutton -in $fmri(evsf) -side top -anchor w -padx 5 -pady 5
	set fmri(level2orth) 0
    } else {
	feat5:setup_level2orth $w $w1
    }
}

for { set j 1 } { $j <= $fmri(evs_vox) } { incr j 1 } {
    set thisev [ expr $fmri(evs_orig) + $j ]
    FileEntry $w1.evfileselect$j -textvariable fmri(evs_vox_$j) -label " EV$thisev (vox)" -title "Select voxelwise EV image file" -width 25 -filetypes IMAGE
    grid $w1.evfileselect$j -in $w1 -row [ expr ( 2 * $fmri(multiple) ) + 5 + $j ] -column 0 -columnspan 6 -pady 3 -sticky w
}

#}}}
	}
    }
    if {[winfo exists $w0.evsnb ]}  { $w0.evsnb compute_size }
    feat5:setup_model_update_contrasts $w 
}    

#}}}
#{{{ feat5:setup_model_update_contrasts_real_per_orig

proc feat5:setup_model_update_contrasts_real_per_orig { w } {
    global fmri

    # first - are there any basis functions OR sinusoidal harmonics? if not return 0
    set is_simple 1
    for { set i 1 } { $i <= $fmri(evs_orig) } { incr i 1 } {
	if { $fmri(convolve$i) > 3 || $fmri(shape$i) == 1 } {
	    set is_simple 0
	}
    }
    if { $is_simple } {
	return 0
    }

    # if there are make sure the number of BF or harmonics is the same for every original EV
    for { set i 2 } { $i <= $fmri(evs_orig) } { incr i 1 } {
	if { $fmri(shape$i) != $fmri(shape1) || $fmri(evs_real.$i) != $fmri(evs_real.1) } {
	    return -1
	}
    }

    # so we're ok - return the number of BF or harmonics

    return $fmri(evs_real.1)	
}

#}}}
#{{{ feat5:setup_model_update_contrasts_mode

proc feat5:setup_model_update_contrasts_mode { w update_gui } {
    global fmri
    # if called from feat5:write, will have been called with mode=C
    if { ! $update_gui } {
	set fmri(con_mode_old) c
    }

    if { $fmri(con_mode) != $fmri(con_mode_old) } {

	if { $update_gui } {
	    $fmri(contrastsf).num.con    configure -textvariable fmri(ncon_$fmri(con_mode))
	    $fmri(contrastsf).num.ftests configure -textvariable fmri(nftests_$fmri(con_mode))
            $fmri(notebook) compute_size
	}

	if { $fmri(con_mode) == "real" || ! $update_gui } {

	    set real_per_orig [ feat5:setup_model_update_contrasts_real_per_orig $w ]
	    if { $real_per_orig == -1 } {
		MxPause "In order to setup contrasts in \"Original EVs\" mode whilst using basis functions or sinusoidal harmonics, all the original EVs must be the same basic shape and generate the same number of real EVs. Please change the EV setup."
		return -1
	    }

	    if { $real_per_orig > 0 } {
		#{{{ do the case of basis functions or sinusoidal harmonics
set fmri(ncon_real)    [ expr $real_per_orig * $fmri(ncon_orig) ]
set fmri(nftests_real) [ expr $fmri(nftests_orig) + $fmri(ncon_orig) ]

# zero all F-tests
for { set Con 1 } { $Con <= $fmri(ncon_real) } { incr Con 1 } {
    for { set F 1 } { $F <= $fmri(nftests_real) } { incr F 1 } {
	set fmri(ftest_real${F}.$Con) 0
    }
}

# set explicitly asked for F-tests
for { set F 1 } { $F <= $fmri(nftests_orig) } { incr F 1 } {
    for { set Con 1 } { $Con <= $fmri(ncon_orig) } { incr Con 1 } {
	if { $fmri(ftest_orig${F}.$Con) == 1 } {
	    for { set con_real_inc 1 } { $con_real_inc <= $real_per_orig } { incr con_real_inc } {
		set fmri(ftest_real${F}.[ expr ( ( $Con - 1 ) * $real_per_orig ) + $con_real_inc ]) 1
	    }
	}
    }
}

# set the rest
set con_real 0
for { set Con 1 } { $Con <= $fmri(ncon_orig) } { incr Con 1 } {

    set ev_real 0
    for { set ev_orig 1 } { $ev_orig <= $fmri(evs_orig) } { incr ev_orig 1 } {
	for { set con_real_inc 1 } { $con_real_inc <= $real_per_orig } { incr con_real_inc } {
	    set fmri(conpic_real.[ expr $con_real + $con_real_inc ]) $fmri(conpic_orig.$Con)
	    set fmri(conname_real.[ expr $con_real + $con_real_inc ]) "$fmri(conname_orig.$Con) ($con_real_inc)"
	    for { set ev_real_inc 1 } { $ev_real_inc <= $real_per_orig } { incr ev_real_inc } {
		if { $con_real_inc == $ev_real_inc } {
		    set fmri(con_real[ expr $con_real + $con_real_inc ].[ expr $ev_real + $ev_real_inc ]) $fmri(con_orig${Con}.$ev_orig)
		} else {
		    set fmri(con_real[ expr $con_real + $con_real_inc ].[ expr $ev_real + $ev_real_inc ]) 0
		}
	    }
	}
	incr ev_real $real_per_orig
    }

    for { set con_real_inc 1 } { $con_real_inc <= $real_per_orig } { incr con_real_inc } {
	set fmri(ftest_real[ expr $Con + $fmri(nftests_orig) ].[ expr $con_real + $con_real_inc ]) 1
    }

    incr con_real $real_per_orig
}

#}}}
	    } else {
		#{{{ do temporal derivates etc.

for { set Con 1 } { $Con <= $fmri(ncon_orig) } { incr Con 1 } {
    set ev_real 1
    for { set ev_orig 1 } { $ev_orig <= $fmri(evs_orig) } { incr ev_orig 1 } {
	set fmri(conpic_real.$Con) $fmri(conpic_orig.$Con)
	set fmri(conname_real.$Con) $fmri(conname_orig.$Con)
	set fmri(con_real${Con}.$ev_real) $fmri(con_orig${Con}.$ev_orig)
	incr ev_real 1
	if { $fmri(deriv_yn$ev_orig) } {
	    set fmri(con_real${Con}.$ev_real) 0
	    incr ev_real 1
	}
    }    

    for { set F 1 } { $F <= $fmri(nftests_orig) } { incr F 1 } {
	set fmri(ftest_real${F}.${Con}) $fmri(ftest_orig${F}.${Con})
    }
}

set fmri(ncon_real) $fmri(ncon_orig)
set fmri(nftests_real) $fmri(nftests_orig)

#}}}
	    }

	}

	set fmri(con_mode_old) $fmri(con_mode)
    }

    return 1
}

#}}}
#{{{ feat5:setup_model_update_contrasts

proc feat5:setup_model_update_contrasts { w { dummy dummy } } {
    global fmri

    #{{{ setup evs_real etc/

set fmri(evs_real) 0

if { $fmri(level) == 1 } {

    for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
	set fmri(evs_real.$j) 1
	
	incr fmri(evs_real.$j) $fmri(deriv_yn$j)
	
	if { $fmri(convolve$j) > 3 } {
	    incr fmri(evs_real.$j) [ expr $fmri(basisfnum$j) - 1 ]
	}

	if { $fmri(shape$j) == 1 } {
	    incr fmri(evs_real.$j) $fmri(nharmonics$j)
	}

	incr fmri(evs_real) $fmri(evs_real.$j)
    }
} else {

    set fmri(evs_real) [ expr $fmri(evs_orig) + $fmri(evs_vox) ]
    set fmri(con_mode) real
    for { set j 1 } { $j <= $fmri(evs_real) } { incr j 1 } {
	set fmri(evs_real.$j) 1
    }
}

#}}}
    for { set i 1 } { $i <= $fmri(ncon_$fmri(con_mode)) } { incr i 1 } {
	if { ! [ info exists fmri(conpic_$fmri(con_mode).$i) ] } {
	    set fmri(conpic_$fmri(con_mode).$i) 1
	    set fmri(conname_$fmri(con_mode).$i) ""
	}
    }

    #{{{ destroy and recreate grid

set w0 $fmri(contrastsf).congrid

if { [ winfo exists $w0 ] } {
    destroy $w0
}

frame $w0

pack $w0 -in $fmri(contrastsf) -side top -anchor w -padx 5 -pady 5

#}}}
    #{{{ first 3 columns

button $w0.pastebutton -command "feat5:multiple_paste \"Contrasts\" $fmri(evs_$fmri(con_mode)) $fmri(ncon_$fmri(con_mode)) fmri con_$fmri(con_mode)" -text "Paste"
grid $w0.pastebutton -in $w0 -row 0 -column 0

for { set i 1 } { $i <= $fmri(ncon_$fmri(con_mode)) } { incr i 1 } {

    if { $fmri(con_mode) == "orig" } {
	label $w0.label$i -text "OC$i "
    } else {
	label $w0.label$i -text "C$i "
    }
#$a
    grid $w0.label$i -in $w0 -row $i -column 0
    balloonhelp_for $w0.label$i "Contrast vector number $i - this will result in Z statistic image number $i"

    checkbutton $w0.conpic$i -variable fmri(conpic_$fmri(con_mode).$i)
    grid $w0.conpic$i -in $w0 -row $i -column 1
    balloonhelp_for $w0.conpic$i "Include contrast $i in web page report? (Turn off if
this contrast is only to be used within F-tests.)"

    entry $w0.conname$i -textvariable fmri(conname_$fmri(con_mode).$i) -width 10
    grid $w0.conname$i -in $w0 -row $i -column 2
}

#}}}
    #{{{ top row and main grid

label $w0.evlabel0 -text "Title"
grid $w0.evlabel0 -in $w0 -row 0 -column 2

set ev_count 1
set ev_counti 1

for { set j 1 } { $j <= $fmri(evs_$fmri(con_mode)) } { incr j 1 } {

    if { $fmri(con_mode) == "real" || $ev_counti == 1 } {

	if { $ev_counti == 1 } {
	    label $w0.evlabel${j} -text "EV$ev_count"
	} else {
	    label $w0.evlabel${j} -text ""
	}
	grid $w0.evlabel${j} -in $w0 -row 0 -column [ expr $j + 2 ]

	for { set i 1 } { $i <= $fmri(ncon_$fmri(con_mode)) } { incr i 1 } {
	    if { ! [ info exists fmri(con_$fmri(con_mode)${i}.${j}) ] } {
		set fmri(con_$fmri(con_mode)${i}.${j}) 0
		if { $i==1 && $j==1 } {
		    set fmri(con_$fmri(con_mode)${i}.${j}) 1
		}
	    }
            SpinBox $w0.con${i}_${j} -textvariable fmri(con_$fmri(con_mode)${i}.${j}) -width 3
	    $w0.con${i}_${j} configure -range {-10000.0 10000 1 } -validate focusout -vcmd  {validNum %W %V %P %s [lindex [[string range %W 0 end-2] cget -range] 0] [lindex [[string range %W 0 end-2] cget -range] 1]} -invcmd { set [%W cget -textvariable] $tempSpin; %W config -validate %v } 
	    grid $w0.con${i}_${j} -in $w0 -row $i -column [ expr $j + 2 ]
            balloonhelp_for $w0.con${i}_${j} "The weight given to EV$j within contrast vector $i."
	}

    }

    if { $fmri(con_mode) == "real" } {
	incr ev_counti 1
	if { $ev_counti > $fmri(evs_real.$ev_count) } {
	    set ev_counti 1
	    incr ev_count 1
	}
    } else {
	incr ev_count 1
    }
}

#}}}
    #{{{ ftests

label $w0.blank -text "       "
grid $w0.blank -in $w0 -row 0 -column [ expr $fmri(evs_real) + 3 ]

for { set i 1 } { $i <= $fmri(nftests_$fmri(con_mode)) } { incr i 1 } {

    label $w0.flabel$i -text "F$i "
    grid $w0.flabel$i -in $w0 -row 0 -column [ expr $i + $fmri(evs_real) + 3 ]
    balloonhelp_for $w0.flabel$i "F-test number $i - this will result in F statistic image number $i"
	
    for { set j 1 } { $j <= $fmri(ncon_$fmri(con_mode)) } { incr j 1 } {
	
	if { ! [ info exists fmri(ftest_$fmri(con_mode)${i}.${j}) ] } {
	    set fmri(ftest_$fmri(con_mode)${i}.${j}) 0
	}

	checkbutton $w0.ftest${i}_${j} -variable fmri(ftest_$fmri(con_mode)${i}.$j)
	grid $w0.ftest${i}_${j} -in $w0 -row $j -column [ expr $i + $fmri(evs_real) + 3 ]
        balloonhelp_for $w0.ftest${i}_${j} "Include contrast vector $j in F-test $i?"
    }
}


if { [winfo exists $fmri(notebook)] } { $fmri(notebook) compute_size }

#}}}
}

#}}}
#{{{ feat5:setup_model_preview

proc feat5:setup_model_preview { w } {
    global fmri

    set fmri(filmsetup) 1

    set problem [ feat5:write $w 1 0 0 $fmri(feat_filename) ]
    if { $problem } {
	return 1
    }

    set count 0
    set w0 ".dialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".dialog[incr count]"
    }

    toplevel $w0 -visual truecolor
    wm title $w0 "Model"
    wm iconname $w0 "Model"

    frame $w0.f
    pack $w0.f -expand yes -fill both -in $w0 -side top
    canvas $w0.f.viewport -yscrollcommand "$w0.f.ysbar set" -xscrollcommand "$w0.xsbar set"
    scrollbar $w0.xsbar -command "$w0.f.viewport xview" -orient horizontal
    scrollbar $w0.f.ysbar -command "$w0.f.viewport yview" -orient vertical
    frame $w0.f.viewport.f
    $w0.f.viewport create window 0 0 -anchor nw -window $w0.f.viewport.f
    bind $w0.f.viewport.f <Configure> "feat5:scrollform_resize $w0 $w0.f.viewport"
    pack $w0.f.viewport -side left -fill both -expand true -in $w0.f

    set graphpic [ image create photo -file [ file rootname $fmri(feat_filename) ].ppm ]
    button $w0.f.viewport.f.btn -command "destroy $w0" -image $graphpic -borderwidth 0
    pack $w0.f.viewport.f.btn -in $w0.f.viewport.f
    balloonhelp_for $w0.f.viewport.f.btn $fmri(design_help)

    return 0
}

#}}}
#{{{ feat5:setup_model_acpreview

proc feat5:setup_model_acpreview { w } {
    global fmri

    set problem [ feat5:write $w 1 0 0 $fmri(feat_filename) ]
    if { $problem } {
	return 1
    }

    set count 0
    set w1 ".dialog[incr count]"
    while { [ winfo exists $w1 ] } {
        set w1 ".dialog[incr count]"
    }

    toplevel $w1 -visual truecolor
    wm title $w1 "Design efficiency"
    wm iconname $w1 "Efficiency"

    set graphpic [ image create photo -file [ file rootname $fmri(feat_filename) ]_cov.ppm ]

    button $w1.btn -command "destroy $w1" -image $graphpic -borderwidth 0
    pack $w1.btn -in $w1
    balloonhelp_for $w1.btn $fmri(cov_help)

    return 0
}

#}}}
#{{{ feat5:setup_model_destroy

proc feat5:setup_model_destroy { w w0 } {

    global fmri

    if { ! [ feat5:setup_model_preview $w ] } {
	set temp $fmri(con_mode)
	unset fmri(con_mode)
	set fmri(con_mode) $temp

	for { set i 1 } { $i <= $fmri(evs_orig) } { incr i 1 } {
	    set temp $fmri(shape$i)
	    unset fmri(shape$i)
	    set fmri(shape$i) $temp
	    set temp $fmri(convolve$i)
	    unset fmri(convolve$i)
	    set fmri(convolve$i) $temp
	}

	destroy $w0
    }
}

#}}}
#{{{ feat5:setup_conmask

proc feat5:setup_conmask { w } {
    global fmri FSLDIR

    #{{{ setup window

    if { [ info exists fmri(c_model) ] && [ winfo exists $fmri(c_model) ] } {
	return 0
    }

    set count 0
    set w0 ".cdialog[incr count]"
    while { [ winfo exists $w0 ] } {
        set w0 ".cdialog[incr count]"
    }

    set fmri(c_model) $w0

    toplevel $w0

    wm title $w0 "Setup Contrast Masking"
    wm iconname $w0 "Contrast Masking"
    wm iconbitmap $w0 @${FSLDIR}/tcl/fmrib.xbm

    frame $w0.f
    pack $w0.f -in $w0 -side top -anchor w

    canvas $w0.f.viewport -yscrollcommand "$w0.f.ysbar set" -xscrollcommand "$w0.xsbar set" -borderwidth 0
    scrollbar $w0.xsbar -command "$w0.f.viewport xview" -orient horizontal
    scrollbar $w0.f.ysbar -command "$w0.f.viewport yview" -orient vertical
    frame $w0.f.viewport.f
    $w0.f.viewport create window 0 0 -anchor nw -window $w0.f.viewport.f
    bind $w0.f.viewport.f <Configure> "feat5:scrollform_resize $w0 $w0.f.viewport"
    pack $w0.f.viewport -side left -fill both -expand true -in $w0.f

    set v $w0.f.viewport.f

#}}}
    #{{{ setup grid

set total [ expr $fmri(ncon_real) + $fmri(nftests_real) ]

for { set C 1 } { $C <= $total } { incr C 1 } {
    if { $C <= $fmri(ncon_real) } {
	label $v.tl$C -text "C$C"
    } else {
	label $v.tl$C -text "F[ expr $C - $fmri(ncon_real)]"
    }
    balloonhelp_for $v.tl$C $fmri(conmask_help) 
    grid $v.tl$C -in $v -column $C -row 0
}

for { set c 1 } { $c <= $total } { incr c 1 } {

    if { $c <= $fmri(ncon_real) } {
	label $v.l$c -text "Mask real Contrast $c with:    "
    } else {
	label $v.l$c -text "Mask real F-test [ expr $c - $fmri(ncon_real)] with:    "
    }
    balloonhelp_for $v.l$c $fmri(conmask_help) 
    grid $v.l$c -in $v -column 0 -row $c

    for { set C 1 } { $C <= $total } { incr C 1 } {

	if { $C != $c } {
	    checkbutton $v.cb${c}_$C -variable fmri(conmask${c}_${C})
            balloonhelp_for $v.cb${c}_$C $fmri(conmask_help) 
	    grid $v.cb${c}_$C -in $v -column $C -row $c
	}
    }
}

#}}}
    #{{{ setup buttons

checkbutton $w0.zeros -variable fmri(conmask_zerothresh_yn) -text "Mask using (Z>0) instead of (Z stats pass thresholding)" 
balloonhelp_for $w0.zeros $fmri(conmask_help) 

button $w0.ok -command "destroy $w0" -text "OK"

pack $w0.ok $w0.zeros -in $w0 -side bottom -padx 3 -pady 5

#}}}
}

#}}}
#{{{ feat5:checkbfcustom

proc feat5:checkbfcustom { w i dummy } {
    global fmri

    if { [ string compare [ file extension $fmri(bfcustom$i) ] .flobs ] == 0 } {
	set fmri(bfcustom$i) $fmri(bfcustom$i)/hrfbasisfns.txt
    }

    if { ! [ file exists $fmri(bfcustom$i) ] } {
	MxPause "Custom HRF convolution file is invalid!"
	return 1
    }

    catch { exec sh -c "wc -l $fmri(bfcustom$i) | awk '{ print \$1 }'" } line_count
    catch { exec sh -c "wc -w $fmri(bfcustom$i) | awk '{ print \$1 }'" } word_count

    set fmri(basisfnum$i) [ expr int ( $word_count / $line_count ) ]
}

#}}}
#{{{ feat5:setup_level2orth

proc feat5:setup_level2orth { w w1 } {
    global fmri

    set fmri(level2orth) 1

    destroy $fmri(evsf).orthbutton $fmri(evsf).orthlabel 

    label $fmri(evsf).orthlabel -text "Orthogonalisations  "
    grid $fmri(evsf).orthlabel -in $w1 -row [ expr 2 + $fmri(multiple) ] -column 0 -columnspan 2

    for { set i 1 } { $i <= $fmri(evs_orig) } { incr i 1 } {
	set fmri(ortho${i}.0) 1
	set fmri(ortho${i}.${i}) 0
	for { set j 1 } { $j <= $fmri(evs_orig) } { incr j 1 } {
	    if { $j != $i } {
		checkbutton $w1.doorth${i}_${j} -variable fmri(ortho${i}.$j)
		grid $w1.doorth${i}_${j} -in $w1 -row [ expr $j + $fmri(multiple) + 1 ] -column [ expr $i + 1 ]
                balloonhelp_for $w1.doorth${i}_${j} "Orthogonalise EV$i wrt EV${j}?"
	    }
	}
    } 
}

#}}}

#}}}
#{{{ feat5:misc_gui

proc feat5:misc_gui { w } {

    global fmri
    set f $fmri(miscf)

    #{{{ balloon help

checkbutton $f.help -variable fmri(help_yn) -text "Balloon help" -command "feat5:updatehelp $w"  -justify right

balloonhelp_for $f.help "And don't expect this message to appear whilst you've turned this
option off!"
feat5:updatehelp $w

#}}}
    #{{{ featwatcher

checkbutton $f.featwatcher -variable fmri(featwatcher_yn) -text "Progress watcher" -justify right
balloonhelp_for $f.featwatcher "Start a web browser to watch the analysis progress?"

#}}}
    #{{{ brain threshold

LabelSpinBox $f.brain_thresh -label "Brain/background threshold, % " -textvariable fmri(brain_thresh) -range {0 100 1 } -width 3 
balloonhelp_for $f.brain_thresh "This is automatically calculated, as a % of the maximum input image
intensity. It is used in intensity normalisation, brain mask
generation and various other places in the analysis."

#}}}
    #{{{ design efficiency

TitleFrame  $f.contrastest -text "Design efficiency" -relief groove 
set fmri(contrastest) $f.contrastest
set cf [ $f.contrastest getframe ]

LabelSpinBox $cf.noise -label "Noise level % " -textvariable fmri(noise) -range {0.0001 1000 .25 } -width 5 
grid $cf.noise -in $cf -column 0 -row 0 -padx  3 -pady 3

LabelSpinBox $cf.noisear -label "Temporal smoothness "  -textvariable fmri(noisear) -range {-0.99 0.99 .1 } -width 5 
grid $cf.noisear -in $cf -column 1 -row 0 -padx 3 -pady 3

LabelSpinBox $cf.critical_z  -label "Z threshold " -textvariable fmri(critical_z) -range {0.0001 100 1 } -width 5 
grid $cf.critical_z -in $cf -column 1 -row 1 -padx 3 -pady 3
balloonhelp_for $cf.critical_z "This is the Z value used to determine what level of activation would
be statistically significant, to be used only in the design
efficiency calculation. Increasing this will result in higher
estimates of required effect."

button $cf.estnoise -text "Estimate from data" -command "feat5:estnoise"
grid $cf.estnoise -in $cf -column 0 -row 1 -padx 3 -pady 3

balloonhelp_for $cf "The \"Noise level %\" and \"Temporal smoothness\" together
characterise the noise in the data, to be used only in the design
efficiency estimation.

The \"Noise level %\" is the standard deviation (over time) for a
typical voxel, expressed as a percentage of the baseline signal level.

The \"Temporal smoothness\" is the smoothness coefficient in a simple
AR(1) autocorrelation model (much simpler than that actually used in
the FILM timeseries analysis but good enough for the efficiency
calculation here).

If you want to get a rough estimate of this noise level and temporal
smoothness from your actual input data, press the \"Estimate from
data\" button (after you have told FEAT where your input data
is). This takes about 30-60 seconds to estimate. This applies just the
spatial and temporal filtering (i.e., no motion correction) that you
have specified in the \"Pre-stats\" section, and gives a reasonable
approximation of the noise characteristics that will remain in the
fully preprocessed data, once FEAT has run."

#}}}
    #{{{ new directory if re-thresholding

optionMenu2 $f.newdir_yn fmri(newdir_yn) 0 "Overwrite original post-stats results" 1 "Copy original FEAT directory for new Post-stats / Registration"

balloonhelp_for $f.newdir_yn "If you are just re-running post-stats or registration, you can either
choose to overwrite the original post-stats and registration results
or create a complete copy of the original FEAT directory, with the new
results in it."

#}}}
    #{{{ cleanup first-level standard-space data

checkbutton $f.sscleanup -variable fmri(sscleanup_yn) -text "Cleanup first-level standard-space images" -justify right

balloonhelp_for $f.sscleanup "When you run a higher-level analysis, the first thing that happens is
that first-level images are transformed into standard-space (in
<firstlevel>.feat/reg_standard subdirectories) for feeding into the
higher-level analysis. This takes up quite a lot of disk space, so if
you want to save disk space, turn this option on and these these
upsampled images will get deleted once they have been fed into the
higher-level analysis. However, generating them can take quite a lot
of time, so if you want to run several higher-level analyses, all
using the same first-level FEAT directories, then leave this option
turned off."

#}}}

    pack $f.help $f.featwatcher $f.brain_thresh $f.contrastest -in $f -anchor w -side top -padx 5 -pady 1
}

#}}}
#{{{ feat5:data_gui

proc feat5:data_gui { w } {

    global FSLDIR fmri
    set f $fmri(dataf)

    #{{{ input type for higher-level

optionMenu2 $f.inputtype fmri(inputtype) -command "feat5:updateselect $w" 1 "Inputs are lower-level FEAT directories" 2 "Inputs are 3D cope images from FEAT directories"
balloonhelp_for $f.inputtype "Select the kind of input you want to feed into the higher-level FEAT
analysis.

If you choose to select \"FEAT directories\", then the higher-level design
will get applied across the selected FEAT directories; each
lower-level FEAT directory forms a \"time-point\" in the higher-level
model. For example, each lower-level FEAT directory represents a
single session in a multiple-session higher-level analysis or a single
subject in a multiple-subject analysis. If the lower-level FEAT
directories contain more than one contrast (cope), then the
higher-level analysis is run separately for each one; in this case,
the higher-level \".gfeat\" directory will end up contain more than
one \".feat\" directory, one for each lower-level contrast. This
option requires all lower-level FEAT directories to include the same
set of contrasts.

If you choose to select \"3D cope images from FEAT directories\", then
you explicitly control which cope corresponds to which \"time-point\"
to be fed into the higher-level analysis. For example, if you have only
one lower-level FEAT directory, containing multiple contrasts (copes),
and you want to carry out a higher-level analysis across these
contrasts, then this is the correct option. With this option (as with
the previous one), the chosen copes will automatically get transformed
into standard space if necesary."

#}}}
    
    #{{{ multiple analyses

frame $f.multiple
set fmri(anal_min) 1
LabelSpinBox $f.multiple.number -label "Number of inputs " -textvariable fmri(multiple) -range " $fmri(anal_min) 10000 1 "  -width 3 -command "$f.multiple.number.spin.e validate; feat5:updateselect $w" -modifycmd "feat5:updateselect $w"
button $f.multiple.setup -text "Select 4D data" -command "feat5:multiple_select $w 0 \"Select input data\" "
pack $f.multiple.number $f.multiple.setup -in $f.multiple -side left -padx 5

if { ! $fmri(inmelodic) } {
    balloonhelp_for $f.multiple "Set the filename of the 4D input image (e.g. /home/sibelius/func.hdr).
You can setup FEAT to process many input images, one after another, as
long as they all require exactly the same analysis. Each one will
generate its own FEAT directory, the name of which is based on the
input data's filename.
Alternatively, if you are running either just \"Post-stats\" or
\"Registration only\", or running \"Higher-level analysis\", the
selection of 4D data changes to the selection of FEAT directories.
Note that in this case you should select the FEAT directories before
setting up anything else in FEAT (such as changing the
thresholds). This is because quite a lot of FEAT settings are loaded
from the first selected FEAT directory, possibly over-writing any
settings which you wish to change!"
} else {
    balloonhelp_for $f.multiple "Set the filename of the 4D input image.

For standard single-session ICA analyses, you can setup multiple input
images and MELODIC will be run separately on each.

For multiple-session ICA analysis (whether concatenating data or using
tensor-ICA) you must setup more than one input to be combined together
in the final analysis."
}

#}}}

    #{{{ output directory

FileEntry $f.outputdir -textvariable fmri(outputdir) -label " Output directory  " -title "Name the output directory" -width 35 -filedialog directory -filetypes { }

balloonhelp_for $f.outputdir "If this is left blank, the output directory name is derived from
the input data name.

If, however, you wish to explicitly choose the output directory name,
for example, so that you can include in the name a hint about the
particular analysis that was carried out, you can set this here.

This output directory naming behaviour is modified if you are setting
up multiple analyses, where you are selecting multiple input data sets
and will end up with multiple output directories. In this case,
whatever you enter here will be used and appended to what would have
been the default output directory name if you had entered nothing."

#}}}

    frame $f.datamain
    #{{{ npts & ndelete

frame $f.datamain.nptsndelete

#{{{ npts

set fmri(npts) 0

if { ! $fmri(inmelodic) } {

    LabelSpinBox $f.datamain.nptsndelete.npts -label "Total volumes " -textvariable fmri(npts) -range {0 2000000 1 }
    balloonhelp_for $f.datamain.nptsndelete.npts "The number of FMRI volumes in the time series, including any initial
volumes that you wish to delete. This will get set automatically once
valid input data has been selected.

Alternatively you can set this number by hand before selecting data so
that you can setup and view a model without having any data, for
experimental planning purposes etc."

} else {

    frame $f.datamain.nptsndelete.npts
    label $f.datamain.nptsndelete.npts.npts1 -text "Total volumes "
    label $f.datamain.nptsndelete.npts.npts2 -textvariable fmri(npts)
    balloonhelp_for $f.datamain.nptsndelete.npts "The number of FMRI volumes in the time series, including any initial
volumes that you wish to delete. This will get set automatically once
valid input data has been selected."
    pack $f.datamain.nptsndelete.npts.npts1 $f.datamain.nptsndelete.npts.npts2 -in $f.datamain.nptsndelete.npts -side left

}

#}}}
#{{{ ndelete

LabelSpinBox $f.datamain.nptsndelete.ndelete -label "       Delete volumes " -textvariable fmri(ndelete) -range {0 200000 1 } -width 3 

if { ! $fmri(inmelodic) } {
    balloonhelp_for $f.datamain.nptsndelete.ndelete "The number of initial FMRI volumes to delete before any further
processing. Typically your experiment would have begun after these
initial scans (sometimes called \"dummy scans\"). These should be the
volumes that are not wanted because steady-state imaging has not yet
been reached - typically two or three volumes. These volumes are
deleted as soon as the analysis is started.

Note that \"Delete volumes\" should not be used to correct for the
time lag between stimulation and the measured response - this is
corrected for in the design matrix by convolving the input stimulation
waveform with a blurring-and-delaying haemodynamic response function.

Most importantly, remember when setting up the design matrix, that the
timings in the design matrix start at t=0 seconds, and this
corresponds to the start of the first image taken after the deleted
scans. In other words, the design matrix starts AFTER the \"deleted
scans\" have been deleted."
} else {
    balloonhelp_for $f.datamain.nptsndelete.ndelete "The number of initial FMRI volumes to delete before any further
processing. Typically your experiment would have begun after these
initial scans (sometimes called \"dummy scans\"). These should be the
volumes that are not wanted because steady-state imaging has not yet
been reached - typically two or three volumes. These volumes are
deleted as soon as the analysis is started."
}

#}}}

pack $f.datamain.nptsndelete.npts $f.datamain.nptsndelete.ndelete -in $f.datamain.nptsndelete -side left

#}}}
    #{{{ TR & highpass

frame $f.datamain.trparadigm_hp

#{{{ TR

LabelSpinBox $f.datamain.trparadigm_hp.tr -label "TR (s) " -textvariable fmri(tr) -range {0.0001 200000 0.25 } 
balloonhelp_for $f.datamain.trparadigm_hp.tr "The time (in seconds) between scanning successive FMRI volumes."

#}}}
#{{{ High pass

LabelSpinBox $f.datamain.trparadigm_hp.paradigm_hp -label "     High pass filter cutoff (s) " -textvariable fmri(paradigm_hp) -range {1.0 200000 5 } -width 5 
balloonhelp_for $f.datamain.trparadigm_hp.paradigm_hp "The high pass frequency cutoff point (seconds), that is, the longest
temporal period that you will allow.

A sensible setting in the case of an rArA or rArBrArB type block
design is the (r+A) or (r+A+r+B) total cycle time.

For event-related designs the rule is not so simple, but in general
the cutoff can typically be reduced at least to 50s.

This value is setup here rather than in Pre-stats because in FEAT it
also affects the generation of the model; the same high pass filtering
is applied to the model as to the data, to get the best possible match
between the model and data."

#}}}

pack $f.datamain.trparadigm_hp.tr $f.datamain.trparadigm_hp.paradigm_hp -in $f.datamain.trparadigm_hp -side left

#}}}

    pack $f.datamain.nptsndelete $f.datamain.trparadigm_hp -in $f.datamain -side top -padx 5 -pady 3 -anchor w
    
    pack $f.multiple $f.datamain -in $fmri(dataf) -anchor w -side top

    #{{{ FSL logo

set graphpic [ image create photo -file ${FSLDIR}/tcl/fsl-logo-tiny.ppm ]
button $f.logo -image $graphpic -command "FmribWebHelp file: ${FSLDIR}/doc/index.html" -borderwidth 0
pack $f.logo -in $fmri(dataf) -anchor e -side bottom -padx 5 -pady 5

#}}}
}

#}}}
#{{{ feat5:prestats_gui

proc feat5:prestats_gui { w } {

    global fmri
    set f $fmri(filteringf)

    #{{{ motion correction

frame $f.mc
label $f.mc.label -text "Motion correction: "
optionMenu2 $f.mc.menu fmri(mc) 0 "None" 1 "MCFLIRT"

pack $f.mc.label $f.mc.menu -side top -side left
balloonhelp_for $f.mc "You will normally want to apply motion correction; this attempts to
remove the effect of subject head motion during the
experiment. MCFLIRT uses FLIRT (FMRIB's Linear Registration Tool)
tuned to the problem of FMRI motion correction, applying rigid-body
transformations.

Note that there is no \"spin history\" (aka \"correction for movement\")
option with MCFLIRT. This is because this is still a poorly understood
correction method which is under further investigation."

#}}}
    #{{{ B0 unwarping

frame $f.unwarpf
set fmri(unwarpf) $f.unwarpf

label $fmri(unwarpf).label -text "B0 unwarping"

checkbutton $fmri(unwarpf).yn -variable fmri(regunwarp_yn) -command "feat5:updateprestats $w"

TitleFrame  $fmri(unwarpf).lf -text "B0 unwarping" -relief groove 
set fmri(unwarpff) [ $fmri(unwarpf).lf getframe ]

set unwarp_files(1) "~"
set unwarp_files_mag(1) "~"

FileEntry $fmri(unwarpff).unwarpsingle -textvariable unwarp_files(1) -label  "Fieldmap       " -title "Select the B0 fieldmap image" -width 35 -filedialog directory  -filetypes IMAGE -command "feat5:multiple_check $w 1 1 0"

button $fmri(unwarpff).unwarpmultiple -text "Select the B0 fieldmap images" \
	-command "feat5:multiple_select $w 1 \"Select the B0 fieldmap images\" "

FileEntry $fmri(unwarpff).unwarpmagsingle -textvariable unwarp_files_mag(1) -label "Fieldmap mag" -title "Select the B0 fieldmap magnitude image" -width 35 -filedialog directory  -filetypes IMAGE -command "feat5:multiple_check $w 2 1 0"

button $fmri(unwarpff).unwarpmagmultiple -text "Select the B0 fieldmap magnitude images" \
	-command "feat5:multiple_select $w 2 \"Select the B0 fieldmap magnitude images\" "

frame $fmri(unwarpff).opts1
LabelSpinBox $fmri(unwarpff).opts1.dwell -label "Effective EPI echo spacing (ms) " -textvariable fmri(dwell) -range { 0.000001 200000 0.1 } -width 5 
LabelSpinBox $fmri(unwarpff).opts1.te -label "  EPI TE (ms) " -textvariable fmri(te) -range {0.000001 200000 1 } -width 5 


frame $fmri(unwarpff).opts2
LabelSpinBox  $fmri(unwarpff).opts2.signallossthresh -label "  % Signal loss threshold " -textvariable fmri(signallossthresh) -range {0 100 1 } -width 3



label $fmri(unwarpff).opts2.label -text "Unwarp direction "
optionMenu2 $fmri(unwarpff).opts2.unwarp_dir fmri(unwarp_dir) x "x" x- "-x" y "y" y- "-y" z "z" z- "-z"
set fmri(unwarp_dir) y-

pack $fmri(unwarpff).opts1.dwell $fmri(unwarpff).opts1.te -in $fmri(unwarpff).opts1 -side left -anchor w
pack $fmri(unwarpff).opts2.label $fmri(unwarpff).opts2.unwarp_dir $fmri(unwarpff).opts2.signallossthresh -in $fmri(unwarpff).opts2 -side left -anchor w

pack $fmri(unwarpff).unwarpsingle $fmri(unwarpff).opts1 $fmri(unwarpff).opts2 -in $fmri(unwarpff) -anchor w -side top -pady 2 -padx 3

pack $fmri(unwarpf).label $fmri(unwarpf).yn -in $fmri(unwarpf) -side left
balloonhelp_for $fmri(unwarpf) "B0 unwarping is carried out using FUGUE. Here you need to enter the B0 fieldmap images which usually require site/scanner/sequence specific processing.  See the PRELUDE/FUGUE documentation for more information on creating these images.   The fieldmap and functional (EPI) images _must_ be in the same orientation (LR/AP/SI labels the same in FSLView), although they do not need to be registered or have the same resolution or exact FOV.  In the GUI, the two images that are required are (1) a fieldmap image which must have units of rad/s, and (2) a brain-extracted and registered magnitude image (this is usually created by running BET on the standard magnitude-only reconstructed image from the fieldmap sequence data).

Next you need to enter the \"Effective EPI echo spacing\" in milliseconds.  This is the time between echoes in successive k-space lines.  If you are using an accelerated sequence (parallel imaging) then the number you need here is the echo spacing for the acquired lines divided by the acceleration factor. The \"EPI TE\" (echo time) is also in milliseconds. Both of these values relate to your FMRI EPI data, not the fieldmap data. 

You also need to specify the \"Unwarp direction\", which is the phase-encoding direction of your FMRI EPI data. The sign of this direction will depend on both the sign of the phase encode blips in the EPI sequence and on the sign of the fieldmap.  As it can be difficult to predict this sign when using a particular site/scanner/sequence for the first time, it is usual to try both positive and negative values in turn and see which gives better undistortion (the wrong sign will increase the amount of distortion rather than decrease it).

Finally, you need to specify a \"% Signal loss threshold\". This determines where the signal loss in the EPI is too great for registration to get a good match between the EPI data and other images. Areas where the % signal loss in the EPI exceeds this threshold will get masked out of the registration process between the EPI and the fieldmap and structural images.

If you are running both motion correction and B0 unwarping, the motion correction resampling does not get applied at the same time as the motion estimation; instead the motion correction gets applied simultaneously with the application of the B0 unwarping, in order to minimise interpolation-related image blurring.

Once this has run, you should definitely check the unwarping section of the Pre-stats report page. In particular you should check that it looks like the unwarping has occurred in the correct direction (and change the unwarp direction and/or sign if it is not)."

#}}}
    #{{{ slice timing correction

frame $f.st
set fmri(stf) $f.st

FileEntry $fmri(stf).st_file -textvariable fmri(st_file) -label "" -title "Select a slice order/timings file" -width 20 -filedialog directory -filetypes * 

label $fmri(stf).label -text "Slice timing correction: "
optionMenu2 $fmri(stf).menu fmri(st) -command "feat5:updateprestats $w" 0 "None" 1 "Regular up (0, 1, 2 ... n-1)" 2 "Regular down (n-1, n-2 ... 0)" 5 "Interleaved (0, 2, 4 ... 1, 3, 5 ... )" 3 "Use slice order file" 4 "Use slice timings file"

pack $fmri(stf).label $fmri(stf).menu -in $fmri(stf) -side top -side left
balloonhelp_for $fmri(stf) "Slice timing correction corrects each voxel's time-series for the fact
that later processing assumes that all slices were acquired exactly
half-way through the relevant volume's acquisition time (TR), whereas
in fact each slice is taken at slightly different times.

Slice timing correction works by using (Hanning-windowed) sinc
interpolation to shift each time-series by an appropriate fraction of
a TR relative to the middle of the TR period. It is necessary to know
in what order the slices were acquired and set the appropriate option
here.

If slices were acquired from the bottom of the brain to the top select 
\"Regular up\".  If slices were acquired from the top of the brain
to the bottom select \"Regular down\".

If the slices were acquired with interleaved order (0, 2, 4 ... 1, 3,
5 ...) then choose the \"Interleaved\" option.

If slices were not acquired in regular order you will need to  use a
slice order file or a slice timings file. If a slice order file is to
be used, create a text file with a single number on each line, where
the first line states which slice was acquired first, the second line
states which slice was acquired second, etc. The first slice is
numbered 1 not 0.

If a slice timings file is to be used, put one value (ie for each
slice) on each line of a text file. The units are in TRs, with 0
corresponding to no shift. Therefore a sensible range of values will
be between -0.5 and 0.5."

#}}}
    #{{{ spin history

#frame $w.sh
#
#label $w.sh.label -text "Adjustment for movement"
#
#checkbutton $w.sh.yn -variable fmri(sh_yn)
#
#pack $w.sh.label $w.sh.yn -in $w.sh -padx 5 -side left
#
#$w.bhelp bind $w.sh -msg "blah"

#}}}
    #{{{ BET brain extraction

frame $f.bet

label $f.bet.label -text "BET brain extraction"
checkbutton $f.bet.yn -variable fmri(bet_yn)
pack $f.bet.label $f.bet.yn -in $f.bet -side left
balloonhelp_for $f.bet "This controls the brain extraction applied to the FMRI data (not to
the structural or standard images used in the registration). It uses
BET brain extraction to create a brain mask from the first volume in
the FMRI data. This is normally better than simple intensity-based
thresholding for getting rid of unwanted voxels in FMRI data. Note
that here, BET is setup to run in a quite liberal way so that there is
very little danger of removing valid brain voxels.

If the field-of-view of the image (in any direction) is less than 30mm
then BET is turned off by default.

Note that, with respect to any structural images used in the
registration, you need to have already run BET on those."

#}}}
    #{{{ spatial filtering

LabelSpinBox  $f.smooth -label "Spatial smoothing FWHM (mm) " -textvariable fmri(smooth) -range {0.0 10000 1 } -width 3
balloonhelp_for $f.smooth "This determines the extent of the spatial smoothing, carried out on
each volume of the FMRI data set separately. This is intended to
reduce noise without reducing valid activation; this is successful as
long as the underlying activation area is larger than the extent of
the smoothing. Thus if you are looking for very small activation areas
then you should maybe reduce smoothing from the default of 5mm, and if
you are looking for larger areas, you can increase it, maybe to 10 or
even 15mm.

To turn off spatial smoothing simply set FWHM to 0."

#}}}
    #{{{ intensity normalization

frame $f.norm

label $f.norm.label -text "Intensity normalization"
checkbutton $f.norm.yn -variable fmri(norm_yn)
pack $f.norm.label $f.norm.yn -in $f.norm -side left
balloonhelp_for $f.norm "This forces every FMRI volume to have the same mean intensity. For
each volume it calculates the mean intensity and then scales the
intensity across the whole volume so that the global mean becomes a
preset constant. This step is normally discouraged - hence is turned
off by default. When this step is not carried out, the whole 4D data
set is still normalised by a single scaling factor (\"grand mean
scaling\") - each volume is scaled by the same amount. This is so that
higher-level analyses are valid."

#}}}
    #{{{ temporal filtering

frame $f.temp
set fmri(temp) $f.temp

label $fmri(temp).label -text "Temporal filtering    "

label $fmri(temp).pslabel -text "Perfusion subtraction"
checkbutton $fmri(temp).ps_yn -variable fmri(perfsub_yn) -command "feat5:updateperfusion $w"

optionMenu2 $fmri(temp).tcmenu fmri(tagfirst) 1 "First timepoint is tag" 0 "First timepoint is control"

label $fmri(temp).hplabel -text "Highpass"
checkbutton $fmri(temp).hp_yn -variable fmri(temphp_yn)

pack $fmri(temp).label $fmri(temp).pslabel $fmri(temp).ps_yn $fmri(temp).hplabel $fmri(temp).hp_yn -in $fmri(temp) -side top -side left
if { ! $fmri(inmelodic) } {
    balloonhelp_for $fmri(temp) "\"Perfusion subtraction\" is a pre-processing step for perfusion FMRI
(as opposed to normal BOLD FMRI) data. It subtracts even from odd
timepoints in order to convert tag-control alternating timepoints into
a perfusion-only signal. If you are setting up a full perfusion model
(where you model the full alternating tag/control timeseries in the
design matrix) then you should NOT use this option. The subtraction
results in a temporal shift of the sampled signal to half a TR
earlier; hence you should ideally shift your model forwards in time by
half a TR, for example by reducing custom timings by half a TR or by
increasing the model shape phase by half a TR. When you select this
option, FILM prewhitening is turned off (because it is not
well-matched to the autocorrelation resulting from the subtraction
filter) and instead the varcope and degrees-of-freedom are corrected
after running FILM in OLS mode. See the \"Perfusion\" section of the
manual for more information.


\"Highpass\" temporal filtering uses a local fit of a straight line
(Gaussian-weighted within the line to give a smooth response) to
remove low frequency artefacts. This is preferable to sharp rolloff
FIR-based filtering as it does not introduce autocorrelations into the
data.

By default, the temporal filtering that is applied to the data will also be
applied to the model."
} else {
    balloonhelp_for $fmri(temp) "\"Perfusion subtraction\" is a pre-processing step for perfusion FMRI
(as opposed to normal BOLD FMRI) data. It subtracts even from odd
timepoints in order to convert tag-control alternating timepoints into
a perfusion-only signal. The subtraction results in a temporal shift
of the sampled signal to half a TR earlier.


\"Highpass\" temporal filtering uses a local fit of a straight line
(Gaussian-weighted within the line to give a smooth response) to
remove low frequency artefacts. This is preferable to sharp rolloff
FIR-based filtering as it does not introduce autocorrelations into the
data.

\"Lowpass\" temporal filtering reduces high frequency noise by Gaussian
smoothing (sigma=2.8s), but also reduces the strength of the signal of
interest, particularly for single-event experiments. It is not
generally considered to be helpful, so is turned off by default."
}

#}}}
    #{{{ melodic

if { ! $fmri(inmelodic) } {
    frame $f.melodic
    label $f.melodic.label -text "MELODIC ICA data exploration"
    checkbutton $f.melodic.yn -variable fmri(melodic_yn)
    pack $f.melodic.label $f.melodic.yn -in $f.melodic -side top -side left
    balloonhelp_for $f.melodic "This runs MELODIC, the ICA (Independent Component Analysis) tool in
FSL. We recommend that you run this, in order to gain insight into
unexpected artefacts or activation in your data.

You can even use this MELODIC output to \"de-noise\" your data; see
the FEAT manual for information on how to do this."
}

#}}}

    feat5:updateprestats $w

    pack $f.mc $fmri(unwarpf) $fmri(stf) $f.bet $f.smooth $f.norm $fmri(temp) -in $f -anchor w -pady 1 -padx 5
    if { ! $fmri(inmelodic) } {
	pack $f.melodic -in $f -anchor w -pady 1 -padx 5
    }
}

#}}}
#{{{ feat5:reg_gui

proc feat5:reg_gui { w } {

    global fmri
    set f $fmri(regf)
    set fmri(regreduce_dof) 0

    #{{{ high res

frame $f.initial_highres

checkbutton $f.initial_highres.yn -variable fmri(reginitial_highres_yn) -command "feat5:updatereg_hr_init $w"

label $f.initial_highres.label -text "Initial structural image"

TitleFrame $f.initial_highres.lf -text "Initial structural image" -relief groove 
set fmri(initial_highresf) [ $f.initial_highres.lf getframe ]

FileEntry $fmri(initial_highresf).initial_highressingle -textvariable initial_highres_files(1) -label "" -title "Select initial structural image" -width 45 -filedialog directory  -filetypes IMAGE -command "feat5:multiple_check $w 3 1 0"

button $fmri(initial_highresf).initial_highresmultiple -text "Select initial structural images" \
	-command "feat5:multiple_select $w 3 \"Select initial structural images\" "

frame $fmri(initial_highresf).opts

label $fmri(initial_highresf).opts.label -text "  Linear "
optionMenu2 $fmri(initial_highresf).opts.search fmri(reginitial_highres_search) 0 "No search" 90 "Normal search" 180 "Full search"
optionMenu2 $fmri(initial_highresf).opts.dof fmri(reginitial_highres_dof) 3 "3 DOF (translation-only)" 6 "6 DOF" 7 "7 DOF" 9 "9 DOF" 12 "12 DOF"

pack  $fmri(initial_highresf).opts.label $fmri(initial_highresf).opts.search $fmri(initial_highresf).opts.dof -in $fmri(initial_highresf).opts -side left

pack $fmri(initial_highresf).initial_highressingle $fmri(initial_highresf).opts -in $fmri(initial_highresf) -anchor w -side top -pady 2 -padx 3
pack $f.initial_highres.yn $f.initial_highres.label -in $f.initial_highres -side left
balloonhelp_for $f.initial_highres "This is the initial high resolution structural image which the low
resolution functional data will be registered to, and this in turn
will be registered to the main highres image. It only makes sense to
have this initial highres image if a main highres image is also
specified and used in the registration. 

One example of an initial highres structural image might be a
medium-quality structural scan taken during a day's scanning, if a
higher-quality image has been previously taken for the subject. A
second example might be a full-brain image with the same MR sequence
as the functional data, useful if the actual functional data is only
partial-brain. It is strongly recommended that this image have
non-brain structures already removed, for example by using BET.

If the field-of-view of the functional data (in any direction) is less
than 120mm, then the registration of the functional data will by
default have a reduced degree-of-freedom, for registration stability.

If you are attempting to register partial field-of-view functional
data to a whole-brain image then \"3 DOF\" is recommended - in this
case only translations are allowed.

If the orientation of any image is different from any other image it
may be necessary to change the search to \"Full search\"."

#}}}
    #{{{ high res2

frame $f.highres

checkbutton $f.highres.yn -variable fmri(reghighres_yn) -command "feat5:updatereg_hr $w"

label $f.highres.label -text "Main structural image"

TitleFrame $f.highres.lf -text "Main structural image" -relief groove 
set fmri(highresf) [ $f.highres.lf getframe ]

FileEntry $fmri(highresf).highressingle -textvariable highres_files(1) -label "" -title "Select main structural image" -width 45 -filedialog directory  -filetypes IMAGE -command "feat5:multiple_check $w 4 1 0"

button $fmri(highresf).highresmultiple -text "Select main structural images" \
	-command "feat5:multiple_select $w 4 \"Select main structural images\" "

frame $fmri(highresf).opts

label $fmri(highresf).opts.label -text "  Linear "
optionMenu2 $fmri(highresf).opts.search fmri(reghighres_search) 0 "No search" 90 "Normal search" 180 "Full search"
optionMenu2 $fmri(highresf).opts.dof fmri(reghighres_dof) 3 "3 DOF (translation-only)" 6 "6 DOF" 7 "7 DOF" 9 "9 DOF" 12 "12 DOF"

pack $fmri(highresf).opts.label $fmri(highresf).opts.search $fmri(highresf).opts.dof -in $fmri(highresf).opts -side left

pack $fmri(highresf).highressingle $fmri(highresf).opts -in $fmri(highresf) -anchor w -side top -pady 2 -padx 3
pack $f.highres.yn $f.highres.label -in $f.highres -side left
balloonhelp_for $f.highres "This is the main high resolution structural image which the low resolution
functional data will be registered to (optionally via the \"initial
structural image\"), and this in turn will be registered to the
standard brain. It is strongly recommended that this image have
non-brain structures already removed, for example by using BET.

If the field-of-view of the functional data (in any direction) is less
than 120mm, then the registration of the functional data will by
default have a reduced degree-of-freedom, for registration stability.

If you are attempting to register partial field-of-view functional
data to a whole-brain image then \"3 DOF\" is recommended - in this
case only translations are allowed.

If the orientation of any image is different from any other image it
may be necessary to change the search to \"Full search\"."

#}}}
    #{{{ standard

frame $f.standard

checkbutton $f.standard.yn -variable fmri(regstandard_yn) -command "feat5:updatereg $w"

label $f.standard.label -text "Standard space"

TitleFrame $f.standard.lf -text "Standard space" -relief groove 
set fmri(standardf) [ $f.standard.lf getframe ]

FileEntry $fmri(standardf).standardentry -textvariable fmri(regstandard) -label "" -title "Select the standard image" -width 45 -filedialog directory  -filetypes IMAGE -command "feat5:multiple_check $w 10 1 0"

frame $fmri(standardf).opts
frame $fmri(standardf).nlopts

label $fmri(standardf).opts.label -text "  Linear "
optionMenu2 $fmri(standardf).opts.search fmri(regstandard_search) 0 "No search" 90 "Normal search" 180 "Full search"
optionMenu2 $fmri(standardf).opts.dof fmri(regstandard_dof) 3 "3 DOF (translation-only)" 6 "6 DOF" 7 "7 DOF" 9 "9 DOF" 12 "12 DOF"

label $fmri(standardf).nlopts.label -text "  Nonlinear"
checkbutton $fmri(standardf).nlopts.nonlinear_yn -variable fmri(regstandard_nonlinear_yn) -command "feat5:updatereg $w"
LabelSpinBox $fmri(standardf).nlopts.nonlinear_warpres -label "Warp resolution (mm) " -textvariable fmri(regstandard_nonlinear_warpres) -range {1 1000 1 } -width 2

if { $fmri(inmelodic) } {
    LabelSpinBox  $fmri(standardf).res -label "   Resampling resolution (mm) " -textvariable fmri(regstandard_res) -range {0.0 50 1 } -width 3
    balloonhelp_for $fmri(standardf).res "If this is set to 0, resampling of your data into standard-space
(e.g., for multi-subject analysis) will be applied at the resolution
of the chosen standard space reference image.

If it is not set to 0, the resampling will be applied at the chosen
resolution. For example, for multi-subject Tensor ICA, you probably
need to set this to 3 or 4 so that the combined multi-subject data is
not too large for the processing to complete."
}

pack $fmri(standardf).opts.label $fmri(standardf).opts.search $fmri(standardf).opts.dof -in $fmri(standardf).opts -side left
pack $fmri(standardf).nlopts.label $fmri(standardf).nlopts.nonlinear_yn -in $fmri(standardf).nlopts -side left

pack $fmri(standardf).standardentry $fmri(standardf).opts $fmri(standardf).nlopts -in $fmri(standardf) -anchor w -side top -pady 2 -padx 3
if { $fmri(inmelodic) } {
    pack $fmri(standardf).res -in $fmri(standardf) -anchor w -side top -pady 2 -padx 3
}

pack $f.standard.yn $f.standard.label -in $f.standard -side left
balloonhelp_for $f.standard "This is the standard (reference) image; it should be an image already in MNI152/Talairach/etc. space, ideally with the non-brain structures already removed.

If the field-of-view of the functional data (in any direction) is less than 120mm, then the registration of the functional data will by default have a reduced degree-of-freedom, for registration stability.

If you are attempting to register partial field-of-view functional data to a whole-brain image then \"3 DOF\" is recommended - in this case only translations are allowed.

If the orientation of any image is different from any other image it may be necessary to change the search to \"Full search\".


If you turn on \"Nonlinear\" then FNIRT will be used to apply nonlinear registration between the subject's structural image and standard space. FLIRT will still be used before FNIRT, to initialise the nonlinear registration. Nonlinear registration only works well between structural images and standard space; you cannot use it without specifying a structural image. FNIRT requires whole head (non-brain-extracted) input and reference images for optimal accuracy; if you turn on nonlinear registration, FEAT will look for the original non-brain-extracted structural and standard space images in the same directory as the brain-extracted images that you input into the GUI, and with the same filename except for the \"_brain\" at the end. It will complain if it can't find these, and if this is not corrected, nonlinear registration will run using the brain-extracted images, which is suboptimal.

The \"Warp resolution\" controls the degrees-of-freedom (amount of fine detail) in the nonlinear warp; it refers to the spacing between the warp field control points. By increasing this you will get a smoother (\"less nonlinear\") warp field and vice versa."

#}}}

    pack $f.initial_highres $f.highres $f.standard -in $f -side top -anchor w -pady 0
}

#}}}

### analysis procedures
#{{{ feat5:getconname

proc feat5:getconname { featdir contrastnumber } {
    source ${featdir}/design.fsf
    if { [ info exists fmri(conname_real.$contrastnumber) ] } {
	return $fmri(conname_real.$contrastnumber)
    } else {
	return ""
    }
}

#}}}
#{{{ feat5:connectivity

proc feat5:connectivity { image } {

    global FSLDIR

    set CONNECTIVITY "26"

#    maybe actually USE this test? but needs careful thought.......
#
#    set CONNECTIVITY "6"
#
#    if { [ expr abs([ exec sh -c "$FSLDIR/bin/fslval $image pixdim3" ]) ] < 3.1 } {
#	set CONNECTIVITY "26"
#    }

    return $CONNECTIVITY
}

#}}}
#{{{ feat5:flirt

proc feat5:flirt { in ref dof search interp existing_mats report init in_weighting } {

    global FSLDIR logout comout fmri

    set out ${in}2$ref

    set costfunction "mutualinfo"
    
    # added by HKL
    if { $in == "highres" && $ref == "standard" }  {
		#set costfunction "mutualinfo"
		set costfunction "corratio"
    } 

    if { $existing_mats } {

	if { $in != "highres" && $ref == "standard" && [ imtest highres2standard_warp ] } {
	    fsl:exec "${FSLDIR}/bin/applywarp --ref=$ref --in=$in --out=$out --warp=highres2standard_warp --premat=${in}2highres.mat"
	    #fsl:exec "${FSLDIR}/bin/applywarp --ref=$ref --in=$in --out=$out --warp=highres2standard_warp --premat=${in}2highres.mat --interp=spline" # added by HKL
	} else {
	    fsl:exec "${FSLDIR}/bin/flirt -ref $ref -in $in -out $out -applyxfm -init ${out}.mat -interp $interp"
	    #fsl:exec "${FSLDIR}/bin/applywarp --ref=$ref --in=$in --out=$out --premat=${out}.mat --interp=spline" # added by HKL
	}

    } else {

	if { $dof == 3 } {
	    set dof "6 -schedule ${FSLDIR}/etc/flirtsch/sch3Dtrans_3dof"
	}

	fsl:exec "${FSLDIR}/bin/flirt -ref $ref -in $in -out $out -omat ${out}.mat -cost $costfunction -dof $dof -searchrx -$search $search -searchry -$search $search -searchrz -$search $search -interp $interp $init $in_weighting"
	#fsl:exec "${FSLDIR}/bin/flirt -ref $ref -in $in -omat ${out}.mat -cost $costfunction -dof $dof -searchrx -$search $search -searchry -$search $search -searchrz -$search $search $init $in_weighting" # added by HKL
	#fsl:exec "${FSLDIR}/bin/applywarp --ref=$ref --in=$in --out=$out --premat=${out}.mat --interp=spline" # added by HKL

	if { $out == "highres2standard" && $fmri(regstandard_nonlinear_yn) } {
	    immv highres2standard highres2standard_linear
            set conf T1_2_MNI152_2mm
            if { [ info exists $fmri(fnirt_config) ] } {
                set conf $fmri(fnirt_config)
            }
	    fsl:exec "${FSLDIR}/bin/fnirt --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=highres2standard --jout=highres2standard_jac --config=$conf --ref=standard_head --refmask=standard_mask --warpres=$fmri(regstandard_nonlinear_warpres),$fmri(regstandard_nonlinear_warpres),$fmri(regstandard_nonlinear_warpres)"
	}

    }

    fsl:exec "${FSLDIR}/bin/convert_xfm -inverse -omat ${ref}2${in}.mat ${out}.mat"

    fsl:exec "${FSLDIR}/bin/slicer $out $ref -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png ${out}1.png ; ${FSLDIR}/bin/slicer $ref $out -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png ${out}2.png ; ${FSLDIR}/bin/pngappend ${out}1.png - ${out}2.png ${out}.png; /bin/rm -f sl?.png"
 
    if { $report != "" } {
	fsl:echo $report "<p>Registration of $in to $ref"
	if { $in == "example_func_orig_distorted" } {
	    fsl:echo $report " (for comparison with unwarped example_func vs highres, shown above)"
	}
	fsl:echo $report "<br><a href=\"reg/${out}.png\"><IMG BORDER=0 SRC=\"reg/${out}.png\" WIDTH=2000></a>"
    }
}

#}}}
#{{{ feat5:find_std

proc feat5:find_std { featdir image } {
    global FSLDIR

    if {  [ file exists ${featdir}/design.lev ] } {
	if { [ imtest ${featdir}/$image ] } {
	    return ${featdir}/$image
	} elseif { [ imtest ${featdir}/bg_image ] } {
	    return ${featdir}/bg_image
	} elseif { [ imtest ${featdir}/example_func ] } {
	    return ${featdir}/example_func
	} else {
	    return 0
	}
    } else {
	if { [ imtest ${featdir}/reg_standard/$image ] } {
	    return ${featdir}/reg_standard/$image
	} elseif { $image == "standard" && [ imtest ${featdir}/reg/standard ] } {
	    return ${featdir}/reg/standard
	} else {
	    return 0
	}
    }
}

#}}}
#{{{ feat5:report_insert

proc feat5:report_insert { pagename sectionlabel insertstring } {
    global report

    feat5:report_insert_start $pagename $sectionlabel
    fsl:echo $pagename "$insertstring"
    feat5:report_insert_stop $pagename $sectionlabel
}

proc feat5:report_insert_start { pagename sectionlabel } {
    global report

    catch { exec sh -c "mv ${pagename} tmp${pagename}" } errmsg
    set iptr [ open tmp${pagename} r ]
    #set report [ open ${pagename} w ]
    set foundit 0

    while { ! $foundit && [ gets $iptr line ] >= 0 } {
	if { [ regexp "<!--${sectionlabel}start-->" $line ] } {
	    set foundit 1
	}
	fsl:echo $pagename $line
    }

    close $iptr
}

proc feat5:report_insert_stop { pagename sectionlabel } {
    global report

    set iptr [ open tmp${pagename} r ]
    set foundit 0

    while { [ gets $iptr line ] >= 0 } {
	if { [ regexp "<!--${sectionlabel}stop-->" $line ] } {
	    set foundit 1
	}
	if { $foundit } {
	    fsl:echo $pagename $line
	}
    }
    
    close $iptr
    exec sh -c "rm -f tmp${pagename}"
}

#}}}
#{{{ stringstrip

proc stringstrip { in ext } {

    set lengthin [ string length $in ]
    set lengthext [ string length $ext ]

    if { $lengthin > $lengthext } {

	if { [ string compare [ string range $in [ expr $lengthin - $lengthext ] $lengthin ] $ext ] == 0 } {
	    return [ string range $in 0 [ expr $lengthin - $lengthext - 1 ] ]
	} else { 
	    return $in
	}

    } else {
	return $in
    }
}

proc feat5:strip { in } {
    set in [ stringstrip $in .ica ]
    set in [ stringstrip $in .gica ]
    set in [ stringstrip $in .feat ]
    set in [ stringstrip $in .gfeat ]
    set in [ remove_ext $in ]
    return $in
}

#}}}
#{{{ feat5:proc_prestats

proc feat5:proc_prestats { session } {

    #{{{ basic setups

    global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

    if { $session == 0 } {
	set session 1
    }

    set funcdata [ remove_ext $feat_files($session) ]

    cd $fmri(outputdir)
    set FD [ pwd ]

    set logout ${FD}/logs/feat2_pre
    fsl:echo $logout "</pre><hr>Prestats<br><pre>"

    if { $fmri(filtering_yn) } {
	fsl:echo report_prestats.html "<HTML><HEAD><link REL=\"stylesheet\" TYPE=\"text/css\" href=\".files/fsl.css\">
<TITLE>FSL</TITLE></HEAD><BODY><OBJECT data=\"report.html\"></OBJECT>
<h2>Pre-stats</h2>
<!--prestatspsstart-->
<!--prestatspsstop-->
<!--prestatsrsstart-->
<!--prestatsrsstop-->" -o

    set ps "<hr><p><b>Analysis methods</b><br>FMRI data processing was carried out using FEAT (FMRI Expert Analysis Tool) Version $fmri(version), part of FSL (FMRIB's Software Library, www.fmrib.ox.ac.uk/fsl)."
    set rs "<p><b>References</b><br>"
    }

#}}}

    #{{{ check npts, delete images, make example_func

# copy data into FEAT dir immediately
fsl:exec "${FSLDIR}/bin/fslmaths $funcdata prefiltered_func_data -odt float"
set funcdata prefiltered_func_data

# check npts
set total_volumes [ exec sh -c "${FSLDIR}/bin/fslnvols $funcdata 2> /dev/null" ]
fsl:echo $logout "Total original volumes = $total_volumes"
if { $total_volumes != $fmri(npts) } {
    fsl:echo $logout "Error - $funcdata has a different number of time points to that in FEAT setup"
    return 1
}

# delete images
if { $fmri(filtering_yn) && $fmri(ndelete) > 0 } {
    fsl:echo $logout "Deleting $fmri(ndelete) volume(s) - BE WARNED for future analysis!"
    set total_volumes [ expr $total_volumes - $fmri(ndelete) ]
    fsl:exec "${FSLDIR}/bin/fslroi $funcdata prefiltered_func_data $fmri(ndelete) $total_volumes"
    set funcdata prefiltered_func_data
}

# choose halfway image and copy to example_func (unless alternative example_func setup)
set target_vol_number [ expr $total_volumes / 2 ]
if { [ imtest $fmri(alternative_example_func) ] } {
    fsl:exec "${FSLDIR}/bin/fslmaths $fmri(alternative_example_func) example_func"
} else {
    fsl:exec "${FSLDIR}/bin/fslroi $funcdata example_func $target_vol_number 1"
} 

#}}}
    
    if { $fmri(filtering_yn) } {

	set ps "$ps The following pre-statistics processing was applied"

	### NO THRESHOLDING OR MASKING IN THESE SECTIONS
	#{{{ motion correction

#mc: 0=none 1=MCFLIRT

if { $fmri(mc) != 0 } {
    set ps "$ps; motion correction using MCFLIRT \[Jenkinson 2002\]"
    set rs "$rs\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR02MJ1\">Jenkinson 2002</a>\] M. Jenkinson and P. Bannister and M. Brady and S. Smith. Improved optimisation for the robust and accurate linear registration and motion correction of brain images. NeuroImage 17:2(825-841) 2002.<br>
    "

    #fsl:exec "${FSLDIR}/bin/mcflirt -in $funcdata -out prefiltered_func_data_mcf -mats -plots -refvol $target_vol_number -rmsrel -rmsabs" # removed by HKL
    fsl:exec "${FSLDIR}/bin/mcflirt -in $funcdata -out prefiltered_func_data_mcf -mats -plots -reffile example_func -rmsrel -rmsabs -spline_final" # added by HKL
    #fsl:exec "${FSLDIR}/bin/mcflirt -in $funcdata -out prefiltered_func_data_mcf -mats -plots -refvol $target_vol_number -rmsrel -rmsabs -spline_final" # added by HKL
    if { ! $fmri(regunwarp_yn) } {
	set funcdata prefiltered_func_data_mcf
    }

    new_file mc
    fsl:exec "/bin/mkdir -p mc ; /bin/mv -f prefiltered_func_data_mcf.mat prefiltered_func_data_mcf.par prefiltered_func_data_mcf_abs.rms prefiltered_func_data_mcf_abs_mean.rms prefiltered_func_data_mcf_rel.rms prefiltered_func_data_mcf_rel_mean.rms mc"
    cd mc
    
    #{{{ make plots

fsl:exec "${FSLDIR}/bin/fsl_tsplot -i prefiltered_func_data_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o rot.png " 
fsl:exec "${FSLDIR}/bin/fsl_tsplot -i prefiltered_func_data_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o trans.png " 
fsl:exec "${FSLDIR}/bin/fsl_tsplot -i prefiltered_func_data_mcf_abs.rms,prefiltered_func_data_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o disp.png " 

#}}}
    #{{{ extract mean displacements

set mcchannel [ open prefiltered_func_data_mcf_abs_mean.rms "r" ]
gets $mcchannel line
scan $line "%f" absrms
set absrms [ expr int($absrms*100.0)/100.0 ]
close $mcchannel

set mcchannel [ open prefiltered_func_data_mcf_rel_mean.rms "r" ]
gets $mcchannel line
scan $line "%f" relrms
set relrms [ expr int($relrms*100.0)/100.0 ]
close $mcchannel

#}}}
    #{{{ web page report

cd $FD

set MC_TOLERANCE 0.5

set mcwarning ""
if { $relrms > $MC_TOLERANCE } {
    set mcwarning " - warning - high levels of motion detected"
}

fsl:echo report_prestats.html "<hr><p><b>MCFLIRT Motion correction</b><br>Mean displacements: absolute=${absrms}mm, relative=${relrms}mm$mcwarning
<p><IMG BORDER=0 SRC=\"mc/rot.png\">
<p><IMG BORDER=0 SRC=\"mc/trans.png\">
<p><IMG BORDER=0 SRC=\"mc/disp.png\">
"

#}}}
}

#}}}
	#{{{ B0 unwarping

if { $fmri(regunwarp_yn) } {

    #{{{ setup stuff

new_file unwarp
fsl:exec "/bin/mkdir -p unwarp"
cd unwarp

set ps "$ps; fieldmap-based EPI unwarping using PRELUDE+FUGUE \[Jenkinson 2003, 2004\]"
set rs "$rs\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR01MJ1\">Jenkinson 2003</a>\] M. Jenkinson. A fast, automated, n-dimensional phase unwrapping algorithm. Magnetic Resonance in Medicine 49(1):193-197 2003.<br>
\[<a href=\"http://www.fmrib.ox.ac.uk/~mark/work/hbm2004.ps\">Jenkinson 2004</a>\] M. Jenkinson. Improving the registration of B0-disorted EPI images using calculated cost function weights. Tenth Int. Conf. on Functional Mapping of the Human Brain 2004.<br>
"

fsl:echo ${FD}/report_prestats.html "<hr><b>FUGUE fieldmap unwarping</b>"

#<p>Summary: comparison of original (distorted) and unwarped example_func<br>
#<IMG BORDER=0 SRC=\"unwarp/EF_UD_movie2.gif\" WIDTH=1000>"

#}}}
    #{{{ do the unwarping calculations

    # FM = space of fieldmap
    # EF = space of example_func
    # UD = undistorted (in any space)
    # D  = distorted (in any space)

    # copy in unwarp input files into reg subdir
    fsl:exec "${FSLDIR}/bin/fslmaths ../example_func EF_D_example_func"
    fsl:exec "${FSLDIR}/bin/fslmaths $unwarp_files($session) FM_UD_fmap"
    fsl:exec "${FSLDIR}/bin/fslmaths $unwarp_files_mag($session) FM_UD_fmap_mag"

    # generate mask for fmap_mag (accounting for the fact that either mag or phase might have been masked in some pre-processing before being enter to FEAT)
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag FM_UD_fmap_mag_brain"
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag -bin FM_UD_fmap_mag_brain_mask -odt short"
    # overwrite mask with bet result if requested and not already run
    if { $fmri(bet_yn) } {
	set nzvox [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap_mag -V | awk '{ print \$1 }'" ]
	set nvox [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap_mag -v | awk '{ print \$1 }'" ]
	set frac_nzvox [ expr $nzvox / $nvox ]
	# only do bet if 90% or more voxels are non-zero to start with
	if { $frac_nzvox > 0.9 } {
	    fsl:exec "${FSLDIR}/bin/bet2 FM_UD_fmap_mag FM_UD_fmap_mag_brain -m"
	} 
    }

    # remask by the non-zero voxel mask of the fmap_rads image (as prelude may have masked this differently before)
    # NB: need to use cluster to fill in holes where fmap=0
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap -abs -bin -mas FM_UD_fmap_mag_brain_mask -mul -1 -add 1 -bin FM_UD_fmap_mag_brain_mask_inv" 
    fsl:exec "${FSLDIR}/bin/cluster -i FM_UD_fmap_mag_brain_mask_inv -t 0.5 --no_table -o FM_UD_fmap_mag_brain_mask_idx"
    set maxidx [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap_mag_brain_mask_idx -R | awk '{ print \$2 }'" ]
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag_brain_mask_idx -thr $maxidx -bin -mul -1 -add 1 -bin -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap_mag_brain_mask"

    # refine mask (remove edge voxels where signal is poor)
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap -sub [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap -k FM_UD_fmap_mag_brain_mask -P 50" ] -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap"
    set thresh50 [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap_mag_brain -P 98" ]
    set thresh50 [ expr $thresh50 / 2.0 ]
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag_brain -thr $thresh50 -bin FM_UD_fmap_mag_brain_mask50"
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag_brain_mask -ero FM_UD_fmap_mag_brain_mask_ero"
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag_brain_mask_ero -add FM_UD_fmap_mag_brain_mask50 -thr 0.5 -bin FM_UD_fmap_mag_brain_mask"
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap"
    # run despiking filter just on the edge voxels
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_mag_brain_mask -ero FM_UD_fmap_mag_brain_mask_ero"
    fsl:exec "$FSLDIR/bin/fugue --loadfmap=FM_UD_fmap --savefmap=FM_UD_fmap_tmp_fmapfilt -m FM_UD_fmap_mag_brain_mask --despike --despikethreshold=2.1"
    fsl:exec "$FSLDIR/bin/fslmaths FM_UD_fmap_tmp_fmapfilt -sub FM_UD_fmap -mas FM_UD_fmap_mag_brain_mask_ero -add FM_UD_fmap FM_UD_fmap"
    fsl:exec "/bin/rm -f FM_UD_fmap_tmp_fmapfilt* FM_UD_fmap_mag_brain_mask_ero* FM_UD_fmap_mag_brain_mask50* FM_UD_fmap_mag_brain_i*"
    
    # now demean
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap -sub [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap -k FM_UD_fmap_mag_brain_mask -P 50" ] -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap"

    # create report picture of fmap overlaid onto whole-head mag image
    set fmapmin [ fsl:exec "${FSLDIR}/bin/fslstats FM_UD_fmap -R | awk '{ print \$1 }'" ]
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap -sub $fmapmin -add 10 -mas FM_UD_fmap_mag_brain_mask grot"
    set fmapminmax [ fsl:exec "${FSLDIR}/bin/fslstats grot -l 1 -p 0.1 -p 95" ]
    fsl:exec "${FSLDIR}/bin/overlay 0 0 FM_UD_fmap_mag -a grot $fmapminmax grot"
    fsl:exec "${FSLDIR}/bin/slicer grot -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png fmap+mag.png"
    fsl:echo ${FD}/report_prestats.html "<p>Brain-masked B0 fieldmap in colour, overlaid on top of fieldmap magnitude image<br>
<a href=\"unwarp/fmap+mag.png\"><IMG BORDER=0 SRC=\"unwarp/fmap+mag.png\" WIDTH=1200></a>"

    # get a sigloss estimate and make a siglossed mag for forward warp
    set epi_te [ expr $fmri(te) / 1000.0 ]
    fsl:exec "${FSLDIR}/bin/sigloss -i FM_UD_fmap --te=$epi_te -m FM_UD_fmap_mag_brain_mask -s FM_UD_fmap_sigloss"
    set siglossthresh [ expr 1.0 - ( $fmri(signallossthresh) / 100.0 ) ]
    fsl:exec "${FSLDIR}/bin/fslmaths FM_UD_fmap_sigloss -mul FM_UD_fmap_mag_brain FM_UD_fmap_mag_brain_siglossed -odt float"

    # make a warped version of FM_UD_fmap_mag to match with the EPI
    set dwell [ expr $fmri(dwell) / 1000.0 ]
    fsl:exec "${FSLDIR}/bin/fugue -i FM_UD_fmap_mag_brain_siglossed --loadfmap=FM_UD_fmap --mask=FM_UD_fmap_mag_brain_mask --dwell=$dwell -w FM_D_fmap_mag_brain_siglossed --nokspace --unwarpdir=$fmri(unwarp_dir)"
    fsl:exec "${FSLDIR}/bin/fugue -i FM_UD_fmap_sigloss             --loadfmap=FM_UD_fmap --mask=FM_UD_fmap_mag_brain_mask --dwell=$dwell -w FM_D_fmap_sigloss             --nokspace --unwarpdir=$fmri(unwarp_dir)"
    fsl:exec "${FSLDIR}/bin/fslmaths FM_D_fmap_sigloss -thr $siglossthresh FM_D_fmap_sigloss"
    #fsl:exec "${FSLDIR}/bin/flirt -in EF_D_example_func -ref FM_D_fmap_mag_brain_siglossed -omat EF_2_FM.mat -o grot -dof 6 -refweight FM_D_fmap_sigloss"
    fsl:exec "${FSLDIR}/bin/flirt -in EF_D_example_func -ref FM_D_fmap_mag_brain_siglossed -omat EF_2_FM.mat -o grot -dof 6 -refweight FM_D_fmap_sigloss -cost mutualinfo" # added by HKL
    fsl:exec "${FSLDIR}/bin/convert_xfm -omat FM_2_EF.mat -inverse EF_2_FM.mat"

    # put fmap stuff into space of EF_D_example_func
    # removed by HKL :
    fsl:exec "${FSLDIR}/bin/flirt -in FM_UD_fmap                -ref EF_D_example_func -init FM_2_EF.mat -applyxfm -out EF_UD_fmap"
    fsl:exec "${FSLDIR}/bin/flirt -in FM_UD_fmap_mag_brain      -ref EF_D_example_func -init FM_2_EF.mat -applyxfm -out EF_UD_fmap_mag_brain"
    fsl:exec "${FSLDIR}/bin/flirt -in FM_UD_fmap_mag_brain_mask -ref EF_D_example_func -init FM_2_EF.mat -applyxfm -out EF_UD_fmap_mag_brain_mask"
    fsl:exec "${FSLDIR}/bin/flirt -in FM_UD_fmap_sigloss        -ref EF_D_example_func -init FM_2_EF.mat -applyxfm -out EF_UD_fmap_sigloss"
    # : removed by HKL
    ## added by HKL :
    #fsl:exec "${FSLDIR}/bin/applywarp --in=FM_UD_fmap                --ref=EF_D_example_func --premat=FM_2_EF.mat --out=EF_UD_fmap" # test w/o spline (HKL) - masking ?
    #fsl:exec "${FSLDIR}/bin/applywarp --in=FM_UD_fmap_mag_brain      --ref=EF_D_example_func --premat=FM_2_EF.mat --out=EF_UD_fmap_mag_brain"  # test w/o spline (HKL)
    #fsl:exec "${FSLDIR}/bin/applywarp --in=FM_UD_fmap_mag_brain_mask --ref=EF_D_example_func --premat=FM_2_EF.mat --out=EF_UD_fmap_mag_brain_mask" # no splines here (HKL)
    #fsl:exec "${FSLDIR}/bin/applywarp --in=FM_UD_fmap_sigloss        --ref=EF_D_example_func --premat=FM_2_EF.mat --out=EF_UD_fmap_sigloss" # no splines here (HKL)
    ## : added by HKL
    fsl:exec "${FSLDIR}/bin/fslmaths EF_UD_fmap_mag_brain_mask -thr 0.5 -bin EF_UD_fmap_mag_brain_mask -odt float"
    fsl:exec "${FSLDIR}/bin/fslmaths EF_UD_fmap_sigloss -thr $siglossthresh EF_UD_fmap_sigloss -odt float"

    # create report pic for sigloss
    fsl:exec "${FSLDIR}/bin/overlay 1 0 EF_UD_fmap_mag_brain -a EF_UD_fmap_sigloss 0 1 grot"
    fsl:exec "${FSLDIR}/bin/slicer grot -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png EF_UD_sigloss+mag.png"
    fsl:echo ${FD}/report_prestats.html "<p>Thresholded signal loss weighting image<br>
<a href=\"unwarp/EF_UD_sigloss+mag.png\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_sigloss+mag.png\" WIDTH=1200></a>"

    # apply warp to EF_D_example_func and save unwarp-shiftmap then convert to unwarp-warpfield
    fsl:exec "${FSLDIR}/bin/fugue --loadfmap=EF_UD_fmap --dwell=$dwell --mask=EF_UD_fmap_mag_brain_mask -i EF_D_example_func -u EF_UD_example_func --unwarpdir=$fmri(unwarp_dir) --saveshift=EF_UD_shift"
    fsl:exec "${FSLDIR}/bin/convertwarp -s EF_UD_shift -o EF_UD_warp -r EF_D_example_func --shiftdir=$fmri(unwarp_dir)"

    # create report pic for shift extent
    set shiftminmax [ fsl:exec "${FSLDIR}/bin/fslstats EF_UD_shift -R -P 1 -P 99" ]
    set shiftminR [ format %.1f [ lindex $shiftminmax 0 ] ]
    set shiftmaxR [ format %.1f [ lindex $shiftminmax 1 ] ]
    set shiftminr [ expr [ lindex $shiftminmax 2 ] * -1.0 ]
    set shiftmaxr [ lindex $shiftminmax 3 ]
    fsl:exec "${FSLDIR}/bin/fslmaths EF_UD_shift -mul -1 grot"
    fsl:exec "${FSLDIR}/bin/overlay 1 0 EF_UD_fmap_mag_brain -a EF_UD_shift 0.0001 $shiftmaxr grot 0.0001 $shiftminr grot"
    fsl:exec "${FSLDIR}/bin/slicer grot -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png EF_UD_shift+mag.png"
    fsl:exec "/bin/cp ${FSLDIR}/etc/luts/ramp.gif .ramp.gif"
    fsl:exec "/bin/cp ${FSLDIR}/etc/luts/ramp2.gif .ramp2.gif"
    fsl:echo ${FD}/report_prestats.html "<p>Unwarping shift map, in voxels &nbsp;&nbsp;&nbsp; ${shiftminR} <IMG BORDER=0 SRC=\"unwarp/.ramp2.gif\"> 0 <IMG BORDER=0 SRC=\"unwarp/.ramp.gif\"> ${shiftmaxR}<br>
<a href=\"unwarp/EF_UD_shift+mag.png\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_shift+mag.png\" WIDTH=1200></a>"

    # create report pics in EF space
    fsl:exec "${FSLDIR}/bin/slicer EF_D_example_func    -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png EF_D_example_func.gif"
    fsl:exec "${FSLDIR}/bin/slicer EF_UD_example_func    -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png EF_UD_example_func.gif"
    fsl:exec "${FSLDIR}/bin/slicer EF_UD_fmap_mag_brain    -s 3 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png EF_UD_fmap_mag_brain.gif"
    fsl:exec "${FSLDIR}/bin/whirlgif -o EF_UD_movie2.gif -time 50 -loop 0 EF_D_example_func.gif EF_UD_example_func.gif"
    fsl:exec "${FSLDIR}/bin/whirlgif -o EF_UD_movie3ud.gif -time 50 -loop 0 EF_UD_example_func.gif EF_UD_fmap_mag_brain.gif"
    fsl:exec "${FSLDIR}/bin/whirlgif -o EF_UD_movie3d.gif -time 50 -loop 0 EF_D_example_func.gif EF_UD_fmap_mag_brain.gif"

    fsl:exec "${FSLDIR}/bin/whirlgif -o EF_UD_movie3.gif -time 50 -loop 0 EF_D_example_func.gif EF_UD_example_func.gif EF_UD_fmap_mag_brain.gif; /bin/rm -f sla* slb* slc* sld* sle* slf* slg* slh* sli* slj* slk* sll* grot*"
    fsl:echo ${FD}/report_prestats.html "<p>Original distorted example_func (example_func_orig_distorted)<br>
<a href=\"unwarp/EF_D_example_func.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_D_example_func.gif\" WIDTH=1200></a>
<p>Undistorted example_func (example_func)<br>
<a href=\"unwarp/EF_UD_example_func.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_example_func.gif\" WIDTH=1200></a>
<p>Non-distorted fieldmap magnitude brain-extracted image in space of example_func (unwarp/EF_UD_fmap_mag_brain)<br>
<a href=\"unwarp/EF_UD_fmap_mag_brain.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_fmap_mag_brain.gif\" WIDTH=1200></a>
<p>Movie of distorted and undistorted example_func images<br>
<a href=\"unwarp/EF_UD_movie2.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_movie2.gif\" WIDTH=1200></a>
<p>Movie of distorted example_func to undistorted fieldmap<br>
<a href=\"unwarp/EF_UD_movie3d.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_movie3d.gif\" WIDTH=1200></a>
<p>Movie of undistorted example_func to undistorted fieldmap<br>
<a href=\"unwarp/EF_UD_movie3ud.gif\"><IMG BORDER=0 SRC=\"unwarp/EF_UD_movie3ud.gif\" WIDTH=1200></a>"

#}}}
    #{{{ apply warping and motion correction to example_func and 4D data

cd $FD

immv example_func example_func_orig_distorted
fsl:exec "${FSLDIR}/bin/applywarp -i example_func_orig_distorted -o example_func -w unwarp/EF_UD_warp -r example_func_orig_distorted --abs"
#fsl:exec "${FSLDIR}/bin/applywarp -i example_func_orig_distorted -o example_func -w unwarp/EF_UD_warp -r example_func_orig_distorted --abs --interp=spline" # added by HKL

# now either apply unwarping one vol at a time (including applying individual mcflirt transforms at same time),
# or if mcflirt transforms don't exist, just apply warp to 4D $funcdata
if { [ file exists mc/prefiltered_func_data_mcf.mat/MAT_0000 ] } {
    fsl:exec "${FSLDIR}/bin/fslsplit $funcdata grot"
    for { set i 0 } { $i < $total_volumes } { incr i 1 } {
	set pad [format %04d $i]
	fsl:exec "${FSLDIR}/bin/applywarp -i grot$pad -o grot$pad --premat=mc/prefiltered_func_data_mcf.mat/MAT_$pad -w unwarp/EF_UD_warp -r example_func --abs --mask=unwarp/EF_UD_fmap_mag_brain_mask"
	#fsl:exec "${FSLDIR}/bin/applywarp -i grot$pad -o grot$pad --premat=mc/prefiltered_func_data_mcf.mat/MAT_$pad -w unwarp/EF_UD_warp -r example_func --abs --mask=unwarp/EF_UD_fmap_mag_brain_mask --interp=spline" # added by HKL
    }
    fsl:exec "${FSLDIR}/bin/fslmerge -t prefiltered_func_data_unwarp [ imglob grot* ]"
    fsl:exec "/bin/rm -f grot*"
} else {
	fsl:exec "${FSLDIR}/bin/applywarp -i $funcdata -o prefiltered_func_data_unwarp -w unwarp/EF_UD_warp -r example_func --abs --mask=unwarp/EF_UD_fmap_mag_brain_mask"
    #fsl:exec "${FSLDIR}/bin/applywarp -i $funcdata -o prefiltered_func_data_unwarp -w unwarp/EF_UD_warp -r example_func --abs --mask=unwarp/EF_UD_fmap_mag_brain_mask --interp=spline" # added by HKL
}

set funcdata prefiltered_func_data_unwarp

#}}}
}

#}}}
	#{{{ slice timing correction

if { $fmri(st) > 0 } {

    set ps "$ps; slice-timing correction using Fourier-space time-series phase-shifting"

    set st_opts ""
    
    switch $fmri(st) {
	2 {
	    set st_opts "--down"
	}
	3 {
	    set st_opts "--ocustom=$fmri(st_file)"
	}
	4 {
	    set st_opts "--tcustom=$fmri(st_file)"
	}
	5 {
	    set st_opts "--odd"
	}
    }

    if { [ info exists fmri(st_opts_d) ] } { 
	fsl:exec "${FSLDIR}/bin/slicetimer -i $funcdata --out=prefiltered_func_data_st -r $fmri(tr) $st_opts -d $fmri(st_opts_d)"
    } else {
	fsl:exec "${FSLDIR}/bin/slicetimer -i $funcdata --out=prefiltered_func_data_st -r $fmri(tr) $st_opts"
    }
    set funcdata prefiltered_func_data_st
}

#}}}

	### THRESHOLDING AND MASKING STARTS HERE
	#{{{ BET

set funcdata_unmasked $funcdata

if { [ info exists fmri(alternative_mask) ] && [ imtest $fmri(alternative_mask) ] } {

    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -mas $fmri(alternative_mask) prefiltered_func_data_altmasked"
    set funcdata prefiltered_func_data_altmasked

} else {

    if { $fmri(bet_yn) } {
	set ps "$ps; non-brain removal using BET \[Smith 2002\]"
	set rs "$rs\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR00SMS2\">Smith 2002</a>\] S. Smith. Fast Robust Automated Brain Extraction. Human Brain Mapping 17:3(143-155) 2002.<br>
    "
	fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -Tmean mean_func"
	fsl:exec "${FSLDIR}/bin/bet2 mean_func mask -f 0.3 -n -m; ${FSLDIR}/bin/immv mask_mask mask"
	fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -mas mask prefiltered_func_data_bet"
	set funcdata prefiltered_func_data_bet
    }

}

#}}}
	#{{{ intensity threshold to create mask then dilate

set int_2_98 [ fsl:exec "${FSLDIR}/bin/fslstats $funcdata -p 2 -p 98" ]
set int2  [ lindex $int_2_98 0 ]
set int98 [ lindex $int_2_98 1 ]
set intensity_threshold    [ expr $int2 + ( $fmri(brain_thresh) * ( $int98 - $int2 ) / 100.0 ) ]

if { $fmri(brain_thresh) > 0 } {
    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -thr $intensity_threshold -Tmin -bin mask -odt char"
    set median_intensity [ fsl:exec "${FSLDIR}/bin/fslstats $funcdata_unmasked -k mask -p 50" ]
    fsl:exec "${FSLDIR}/bin/fslmaths mask -dilF mask"
    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata_unmasked -mas mask prefiltered_func_data_thresh"
    set funcdata prefiltered_func_data_thresh
} else {
    fsl:exec "${FSLDIR}/bin/fslmaths example_func -mul 0 -add 1 mask -odt char"
    set median_intensity [ fsl:exec "${FSLDIR}/bin/fslstats $funcdata -p 90" ]
}

#}}}
	#{{{ spatial filtering

if { $fmri(smooth) > 0.01 } {
    set smoothsigma [ expr $fmri(smooth) / 2.355 ]
    set susan_int [ expr ( $median_intensity - $int2 ) * 0.75 ]
    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -Tmean mean_func"
    fsl:exec "${FSLDIR}/bin/susan $funcdata $susan_int $smoothsigma 3 1 1 mean_func $susan_int prefiltered_func_data_smooth"
    fsl:exec "${FSLDIR}/bin/fslmaths prefiltered_func_data_smooth -mas mask prefiltered_func_data_smooth"
    set funcdata prefiltered_func_data_smooth
    set ps "$ps; spatial smoothing using a Gaussian kernel of FWHM $fmri(smooth)mm"
}

#}}}
	#{{{ intensity normalization

set normmean 10000

if { $fmri(norm_yn)} {
    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -inm $normmean prefiltered_func_data_intnorm"
    set ps "$ps; multiplicative mean intensity normalization of the volume at each timepoint"
} else {
    set scaling [ expr $normmean / $median_intensity ]
    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -mul $scaling prefiltered_func_data_intnorm"
    set ps "$ps; grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
}

set funcdata prefiltered_func_data_intnorm

#}}}
	#{{{ Perfusion subtraction

if { $fmri(perfsub_yn) } {

    set ps "$ps; control-tag perfusion subtraction with half-TR sinc interpolation and no decimation"

    set perfinvert ""
    if { ! $fmri(tagfirst) } {
	set perfinvert "-c"
    }

    fsl:exec "${FSLDIR}/bin/perfusion_subtract $funcdata prefiltered_func_data_perfsub $perfinvert"

    set funcdata prefiltered_func_data_perfsub
}

#}}}
	#{{{ Temporal filtering

if { $fmri(temphp_yn) || $fmri(templp_yn) } {

    set hp_sigma_vol -1
    if { $fmri(temphp_yn) } {
	set hp_sigma_sec [ expr $fmri(paradigm_hp) / 2.0 ]
	set hp_sigma_vol [ expr $hp_sigma_sec / $fmri(tr) ]
	set ps "$ps; highpass temporal filtering (Gaussian-weighted least-squares straight line fitting, with sigma=${hp_sigma_sec}s)"
    }

    set lp_sigma_vol -1
    if { $fmri(templp_yn) } {
	set lp_sigma_sec 2.8
	set lp_sigma_vol [ expr $lp_sigma_sec / $fmri(tr) ]
	set ps "$ps; Gaussian lowpass temporal filtering, with sigma=${lp_sigma_sec}s"
    }

    fsl:exec "${FSLDIR}/bin/fslmaths $funcdata -bptf $hp_sigma_vol $lp_sigma_vol prefiltered_func_data_tempfilt"
    set funcdata prefiltered_func_data_tempfilt
}

#}}}

	fsl:exec "${FSLDIR}/bin/fslmaths $funcdata filtered_func_data"
	set ps "$ps."
	set absbrainthresh [ expr $fmri(brain_thresh) * $normmean / 100.0 ]

	#{{{ set TR in header of filtered_func_data if not already correct

set IMTR [ exec sh -c "$FSLDIR/bin/fslval filtered_func_data pixdim4" ]

if { [ expr abs($IMTR - $fmri(tr)) ] > 0.01 } {
    fsl:exec "${FSLDIR}/bin/fslhd -x filtered_func_data | sed 's/  dt = .*/  dt = '$fmri(tr)'/g' > tmpHeader"
    fsl:exec "${FSLDIR}/bin/fslcreatehd tmpHeader filtered_func_data"
    fsl:exec "/bin/rm tmpHeader"
}

#}}}
	#{{{ MELODIC

if { $fmri(melodic_yn) } {
    set ps "$ps ICA-based exploratory data analysis was carried out using MELODIC \[Beckmann 2004\], in order to investigate the possible presence of unexpected artefacts or activation."
    set rs "$rs\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR02CB1\">Beckmann 2004</a>\] C.F. Beckmann and S.M. Smith. Probabilistic Independent Component Analysis for Functional Magnetic Resonance Imaging. IEEE Trans. on Medical Imaging 23:2(137-152) 2004.<br>
    "

    fsl:echo report_prestats.html "<hr><a href=\"filtered_func_data.ica/report/00index.html\">MELODIC data exploration report</a>"

    fsl:exec "${FSLDIR}/bin/melodic -i filtered_func_data -o filtered_func_data.ica -v --nobet --bgthreshold=1 --tr=$fmri(tr) -d 0 --mmthresh=\"0.5\" --report --guireport=../../report.html "
}

#}}}

    } else {
	#{{{ prepare data if no prestats

fsl:exec "${FSLDIR}/bin/fslmaths $funcdata filtered_func_data"

fsl:exec "${FSLDIR}/bin/fslmaths filtered_func_data -Tmin -bin mask -odt char"

set absbrainthresh [ fsl:exec "${FSLDIR}/bin/fslstats filtered_func_data -k mask -R | awk '{ print \$1 }' -" ]

#}}}
    }

    #{{{ finish up

fsl:exec "${FSLDIR}/bin/fslmaths filtered_func_data -Tmean mean_func"

if { $fmri(brain_thresh) == 0 } {
    set absbrainthresh [ fsl:exec "$FSLDIR/bin/fslstats filtered_func_data -R | awk '{ print \$1 }' -" ]
} 

fsl:echo absbrainthresh.txt $absbrainthresh

fsl:exec "/bin/rm -rf prefiltered_func_data*" 

if { $fmri(filtering_yn) } {
    feat5:report_insert report_prestats.html prestatsps $ps
    feat5:report_insert report_prestats.html prestatsrs $rs
    fsl:echo report_prestats.html "</BODY></HTML>"
}

return 0

#}}}
}

#}}}
#{{{ feat5:proc_film

proc feat5:proc_film { session } {

    #{{{ basic setups

    global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL confoundev_files

    cd $fmri(outputdir)

    set logout logs/feat3_film
    fsl:echo $logout "</pre><hr>Stats<br><pre>"

    fsl:echo report_stats.html "<HTML><HEAD><link REL=\"stylesheet\" TYPE=\"text/css\" href=\".files/fsl.css\">
<TITLE>FSL</TITLE></HEAD><BODY><OBJECT data=\"report.html\"></OBJECT>
<h2>Stats</h2>
<!--statspsstart-->
<!--statspsstop-->
<!--statsrsstart-->
<!--statsrsstop-->" -o

    if { [ file exists design.png ] } {
	fsl:echo report_stats.html "<hr><p><b>Design matrix</b><br><a href=\"design.mat\"><IMG BORDER=0 SRC=\"design.png\"></a>"
	if { [ file exists design_cov.png ] } {
	    fsl:echo report_stats.html "<p><b>Covariance matrix & design efficiency</b><br><IMG BORDER=0 SRC=\"design_cov.png\">"
	}
    }

    set ps "<hr><p><b>Analysis methods</b><br>FMRI data processing was carried out using FEAT (FMRI Expert Analysis Tool) Version $fmri(version), part of FSL (FMRIB's Software Library, www.fmrib.ox.ac.uk/fsl)."
    set rs "<p><b>References</b><br>"

#}}}

    # copy input timing files into FEAT directory for future reference
    new_file custom_timing_files
    for { set evs 1 } { $evs <= $fmri(evs_orig) } { incr evs 1 } {
	if { $fmri(shape${evs}) == 2 || $fmri(shape${evs}) == 3 } {
	    fsl:exec "mkdir -p custom_timing_files ; /bin/cp $fmri(custom${evs}) custom_timing_files/ev${evs}.txt"
	}
    }

    # create confoundevs.txt file if asked for (either via confounds or via motion pars)
    if { $fmri(confoundevs) && [ file exists $confoundev_files($session) ] } {
        if { $fmri(motionevs) > 0 && [ file exists mc/prefiltered_func_data_mcf.par ] } {
	    catch { fsl:exec "paste -d ' ' mc/prefiltered_func_data_mcf.par $confoundev_files($session) > confoundevs.txt" } ErrMsg
        } else {
            catch { fsl:exec "cp $confoundev_files($session) confoundevs.txt" } ErrMsg
        }
    } else {
        if { $fmri(motionevs) > 0 && [ file exists mc/prefiltered_func_data_mcf.par ] } {
            catch { fsl:exec "cp mc/prefiltered_func_data_mcf.par confoundevs.txt" } ErrMsg
        }       
    }
    # apply the confounds using feat_model when they exist
    if { [ file exists confoundevs.txt ] } {
        catch { fsl:exec "$FSLDIR/bin/feat_model design confoundevs.txt" } ErrMsg
    }

    set absbrainthresh [ exec sh -c "cat absbrainthresh.txt" ]

    set film_text " with local autocorrelation correction"
    set film_opts "-sa -ms 5"
    if { [ info exists fmri(susan_bt) ] && [ info exists fmri(tukey_num) ] } { set film_opts "-sa -ms $fmri(susan_ms) -epith $fmri(susan_bt) -v -tukey $fmri(tukey_num)" }
    if { ! $fmri(prewhiten_yn) } {
	set film_opts "-noest"
	set film_text ""
    }

    new_file stats
    
    fsl:exec "$FSLDIR/bin/film_gls -rn stats $film_opts filtered_func_data design.mat $absbrainthresh"

    if { ! [ imtest stats/pe1 ] } {
	fsl:echo report.log "Error: FILM did not complete - it probably ran out of memory"
	fsl:echo "" "Error: FILM did not complete - it probably ran out of memory"
	return 1
    }

    set ps "$ps Time-series statistical analysis was carried out using FILM $film_text \[Woolrich 2001\]."
    set rs "$rs\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR01MW1\">Woolrich 2001</a>\] M.W. Woolrich, B.D. Ripley, J.M. Brady and S.M. Smith. Temporal Autocorrelation in Univariate Linear Modelling of FMRI Data. NeuroImage 14:6(1370-1386) 2001.<br>
"

    # correct stats for reduced DOF and altered whitened DM if perfusion subtraction was run
    if { $fmri(perfsub_yn) } {
	set THEDOF [ expr ( $fmri(npts) / 2 ) - $fmri(evs_real) ]
	if { $THEDOF < 1 } {
	    set THEDOF 1
	}
	fsl:exec "echo $THEDOF > stats/dof"
	fsl:exec "${FSLDIR}/bin/fslmaths stats/corrections -mul 2 stats/corrections"
    }

    # spatial smoothnes estimation
    fsl:exec "$FSLDIR/bin/smoothest -d [ exec sh -c "cat stats/dof" ] -m mask -r stats/res4d > stats/smoothness"

    #{{{ finish up

feat5:report_insert report_stats.html statsps $ps
feat5:report_insert report_stats.html statsrs $rs

fsl:echo report_stats.html "</BODY></HTML>"

return 0

#}}}
}

#}}}
#{{{ feat5:proc_poststats

proc feat5:proc_poststats { rerunning stdspace } {

    #{{{ basic setups

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat4_post

if { ! $rerunning } {
    fsl:echo $logout "</pre><hr>Post-stats<br><pre>"

    fsl:echo report_poststats.html "<HTML><HEAD><link REL=\"stylesheet\" TYPE=\"text/css\" href=\".files/fsl.css\">
<TITLE>FSL</TITLE></HEAD><BODY><OBJECT data=\"report.html\"></OBJECT>
<h2>Post-stats</h2>
<!--poststatspsstart-->
<!--poststatspsstop-->
<!--poststatsrsstart-->
<!--poststatsrsstop-->
<!--poststatspicsstart-->
<!--poststatspicsstop-->
<!--poststatstsplotstart-->
<!--poststatstsplotstop-->
" -o

    set ps "<hr><p><b>Analysis methods</b><br>FMRI data processing was carried out using FEAT (FMRI Expert Analysis Tool) Version $fmri(version), part of FSL (FMRIB's Software Library, www.fmrib.ox.ac.uk/fsl)."
    set rs "<p><b>References</b><br>"

    if { $fmri(level) == 1 } {
	set FTESTS ""
	if { [ file exists design.fts ] } {
	    set FTESTS "-f design.fts"
	}
	fsl:exec "$FSLDIR/bin/contrast_mgr $FTESTS stats design.con"
    }
}

#}}}

    if { $fmri(thresh) == 0 } {
	return 0
    }

    set maskcomments "<p>"
    
    #{{{ setup raw stats list

cd ${FD}/stats
set rawstatslist [ remove_ext [ lsort -dictionary [ imglob zstat*.* ] ] [ lsort -dictionary [ imglob zfstat*.* ] ] ]
cd ${FD}

#}}}
    #{{{ setup standard-space/non-standard-space thingies

set STDOPT   ""
set STDEXT   ""
set SLICER   "-A"
set VOXorMM  ""

if { $stdspace != 0 } {
    set STDOPT   "-std"
    set STDEXT   "_std"
    set SLICER   "-S 2"
    set VOXorMM  "--mm"
}

#}}}
    #{{{ brain-mask Z stats and find smoothness

foreach rawstats $rawstatslist {

    if { ! $rerunning } {
	fsl:exec "$FSLDIR/bin/fslmaths stats/$rawstats -mas mask thresh_$rawstats"

	if { $fmri(threshmask) != "" && [ imtest $fmri(threshmask) ] } {
	    fsl:exec "$FSLDIR/bin/fslmaths thresh_$rawstats -mas $fmri(threshmask) thresh_$rawstats"
	    set maskcomments "<p>Z-stat images were masked with $fmri(threshmask) before thresholding.<br>"
	}
    }

    if { [ file exists stats/smoothness ] } {
	set fmri(DLH$rawstats)     [ exec sh -c " grep DLH    stats/smoothness | awk '{ print \$2 }'" ]
	set fmri(RESELS$rawstats)  [ exec sh -c " grep RESELS stats/smoothness | awk '{ print \$2 }'" ]
    } else {
	fsl:exec "$FSLDIR/bin/smoothest -m mask -z stats/$rawstats > stats/${rawstats}.smoothness"
	set fmri(DLH$rawstats)     [ exec sh -c " grep DLH    stats/${rawstats}.smoothness | awk '{ print \$2 }'" ]
	set fmri(RESELS$rawstats)  [ exec sh -c " grep RESELS stats/${rawstats}.smoothness | awk '{ print \$2 }'" ]
    }

    if { ! $rerunning } {
	set fmri(VOLUME$rawstats) [ exec sh -c " ${FSLDIR}/bin/fslstats thresh_$rawstats -V | awk '{ print \$1 }'" ]
	fsl:exec "echo $fmri(VOLUME$rawstats) > thresh_${rawstats}.vol"
    } else {
	if { ! [ info exists fmri(VOLUME$rawstats) ] } {
	    if { [ file exists thresh_${rawstats}.vol ] } {
		set fmri(VOLUME$rawstats) [ exec sh -c "cat thresh_${rawstats}.vol" ]
	    } else {
		set fmri(VOLUME$rawstats) [ exec sh -c "${FSLDIR}/bin/fslstats mask -V | awk '{ print \$1 }'" ]
	    }
	}
    }

    fsl:echo $logout "$rawstats: DLH=$fmri(DLH$rawstats) VOLUME=$fmri(VOLUME$rawstats) RESELS=$fmri(RESELS$rawstats)"

}

#}}}
    #{{{ thresholding and contrast masking

if { ! $rerunning } {

    set firsttime 1
    foreach rawstats $rawstatslist {
	set i [ string trimleft $rawstats "abcdefghijklmnopqrstuvwxyz_" ]

	if { $firsttime == 1 } {
	    set ps "$ps Z (Gaussianised T/F) statistic images were thresholded"
	}

	if { $fmri(thresh) < 3 } {
	    #{{{ voxel-based thresholding

if { $firsttime == 1 } {
    if { $fmri(thresh) == 1 } {
	set ps "$ps at P=$fmri(prob_thresh) (uncorrected)."
	set zthresh [ fsl:exec "${FSLDIR}/bin/ptoz $fmri(prob_thresh)" ]
    } else {
	set ps "$ps using GRF-theory-based maximum height thresholding with a (corrected) significance threshold of P=$fmri(prob_thresh) \[Worsley 2001]."
	set rs "$rs\[Worsley 2001\] K.J. Worsley. Statistical analysis of activation images. Ch 14, in Functional MRI: An Introduction to Methods,
eds. P. Jezzard, P.M. Matthews and S.M. Smith. OUP, 2001.<br>
"
    }
}

if { $fmri(thresh) == 2 } {
    set nResels [ expr int ( $fmri(VOLUME$rawstats) / $fmri(RESELS$rawstats) ) ]
    if { $nResels < 1 } { set nResels 1 }
    set zthresh [ fsl:exec "${FSLDIR}/bin/ptoz $fmri(prob_thresh) -g $nResels" ]
}

fsl:exec "$FSLDIR/bin/fslmaths thresh_$rawstats -thr $zthresh thresh_$rawstats"

#}}}
	} else {
	    #{{{ cluster thresholding

if { $firsttime == 1 } {
    set ps "$ps using clusters determined by Z>$fmri(z_thresh) and a (corrected) cluster significance threshold of P=$fmri(prob_thresh) \[Worsley 2001]."
    set rs "$rs\[Worsley 2001\] K.J. Worsley. Statistical analysis of activation images. Ch 14, in Functional MRI: An Introduction to Methods,
eds. P. Jezzard, P.M. Matthews and S.M. Smith. OUP, 2001.<br>
"
}

set COPE ""
if { [ string first "zfstat" $rawstats ] < 0 && [ imtest stats/cope${i} ] } {
    set COPE "-c stats/cope$i"
}

fsl:exec "$FSLDIR/bin/cluster -i thresh_$rawstats $COPE -t $fmri(z_thresh) -p $fmri(prob_thresh) -d $fmri(DLH$rawstats) --volume=$fmri(VOLUME$rawstats) --othresh=thresh_$rawstats -o cluster_mask_$rawstats --connectivity=[ feat5:connectivity thresh_$rawstats ] $VOXorMM --olmax=lmax_${rawstats}${STDEXT}.txt > cluster_${rawstats}${STDEXT}.txt"

fsl:exec "$FSLDIR/bin/cluster2html . cluster_$rawstats $STDOPT"

#}}}
	}

	set firsttime 0
    }

    #{{{ contrast masking

if { $fmri(conmask1_1) } {

    fsl:exec "mkdir -p conmask"

    foreach rawstats $rawstatslist {

	set i [ string trimleft $rawstats "abcdefghijklmnopqrstuvwxyz_" ]

	# check for being F-test
	set I $i
	if { [ string first "zstat" $rawstats ] == -1 } {
	    incr I $fmri(ncon_real)
	}

	set theinput thresh_$rawstats

	for { set C 1 } { $C <= [ expr $fmri(ncon_real) + $fmri(nftests_real) ] } { incr C } {
	    if { $C != $I } {

		set F ""
		set c $C
		if { $C > $fmri(ncon_real) } {
		    set F f
		    set c [ expr $C - $fmri(ncon_real) ]
		}

		if { $fmri(conmask${I}_$C) } {
		    
		    set themask thresh_z${F}stat$c
		    if { $fmri(conmask_zerothresh_yn) } {
			set themask stats/z${F}stat$c
		    }

		    fsl:echo $logout "Masking $theinput with $themask"

		    set maskcomments "$maskcomments
After all thresholding, $rawstats was masked with $themask.<br>"

		    if { [ imtest $themask ] } {
			fsl:exec "${FSLDIR}/bin/fslmaths $theinput -mas $themask conmask/thresh_$rawstats"
		    } else {
			fsl:exec "${FSLDIR}/bin/fslmaths $theinput -mul 0 conmask/thresh_$rawstats"
		    }

		    set theinput conmask/thresh_$rawstats
		}
		
	    }
	}
    }

    fsl:exec "/bin/mv -f conmask/* . ; rmdir conmask"

    #{{{ redo clustering

if { $fmri(thresh) == 3 } {
    foreach rawstats $rawstatslist {
	set i [ string trimleft $rawstats "abcdefghijklmnopqrstuvwxyz_" ]
	set COPE ""
	if { [ string first "zfstat" $rawstats ] < 0 && [ imtest stats/cope${i} ] } {
	    set COPE "-c stats/cope$i"
	}

	# we're not going to re-test cluster size so pthresh is set to 1000

	fsl:exec "$FSLDIR/bin/cluster -i thresh_$rawstats $COPE -t $fmri(z_thresh) -p $fmri(prob_thresh) -d $fmri(DLH$rawstats) --volume=$fmri(VOLUME$rawstats) --othresh=thresh_$rawstats -o cluster_mask_$rawstats --connectivity=[ feat5:connectivity thresh_$rawstats ] $VOXorMM --olmax=lmax_${rawstats}${STDEXT}.txt > cluster_${rawstats}${STDEXT}.txt"

	fsl:exec "$FSLDIR/bin/cluster2html . cluster_$rawstats $STDOPT"
    }
}

#}}}
}

#}}}
}

#}}}
    #{{{ re-run cluster for StdSpace

if { $rerunning && [ file exists reg/example_func2standard.mat ] && $fmri(thresh) == 3 } {

    set z_thresh    $fmri(z_thresh)
    set prob_thresh $fmri(prob_thresh)

    if { $fmri(analysis) == 0 } {
	set z_thresh    [ exec sh -c " grep 'set fmri(z_thresh)'    design.fsf | awk '{ print \$3 }'" ]
	set prob_thresh [ exec sh -c " grep 'set fmri(prob_thresh)' design.fsf | awk '{ print \$3 }'" ]
    }

    foreach rawstats $rawstatslist {

	set i [ string trimleft $rawstats "abcdefghijklmnopqrstuvwxyz_" ]

	set COPE ""
	if { [ string first "zfstat" $rawstats ] < 0 && [ imtest stats/cope${i} ] } {
	    set COPE "-c stats/cope$i"
	}

	set stdxfm "-x reg/example_func2standard.mat"
	if { [ imtest reg/highres2standard_warp ] } {
	    set stdxfm "-x reg/example_func2highres.mat --warpvol=reg/highres2standard_warp"
	}

	fsl:exec "$FSLDIR/bin/cluster -i thresh_$rawstats ${COPE} -t $z_thresh -p $prob_thresh -d $fmri(DLH$rawstats) --volume=$fmri(VOLUME$rawstats) $stdxfm --stdvol=reg/standard --mm --connectivity=[ feat5:connectivity thresh_$rawstats ] --olmax=lmax_${rawstats}_std.txt > cluster_${rawstats}_std.txt"
	fsl:exec "$FSLDIR/bin/cluster2html . cluster_${rawstats} -std"
    }
}

#}}}
    #{{{ rendering

if { ! $rerunning } {

    #{{{ Find group Z min and max

if { $fmri(zdisplay) == 0 } {

    set fmri(zmin) 100000
    set fmri(zmax) -100000

    foreach rawstats $rawstatslist {
    
	set zminmax [ fsl:exec "${FSLDIR}/bin/fslstats thresh_$rawstats -l 0.0001 -R 2>/dev/null" ]
	set zmin [ lindex $zminmax 0 ]
	set zmax [ lindex $zminmax 1 ]

	# test for non-empty thresh_zstats image
	if { $zmax > 0.0001 } {
	    if { $fmri(zmin) > $zmin } {
		set fmri(zmin) $zmin
	    }
	    if { $fmri(zmax) < $zmax } {
		set fmri(zmax) $zmax
	    }
	}
    }

    if { $fmri(zmin) > 99999 } {
	set fmri(zmin) 2.3
	set fmri(zmax) 8
    }
}

fsl:echo $logout "Rendering using zmin=$fmri(zmin) zmax=$fmri(zmax)"

#}}}

    set underlying example_func
    #    if { ! [ imtest $underlying ] } {
    #	set underlying mean_highres
    #    }

    set firsttime 1
    foreach rawstats $rawstatslist {
	
	set i [ string trimleft $rawstats "abcdefghijklmnopqrstuvwxyz_" ]
	
	if { [ string first "zstat" $rawstats ] < 0 || $fmri(conpic_real.$i) == 1 } {
	    #{{{ Rendering

set conname "$rawstats"
if { [ string first "zfstat" $rawstats ] < 0 } {
    set conname "$conname &nbsp;&nbsp;-&nbsp;&nbsp; C${i}"
    if { $fmri(conname_real.$i) != "" } {
	set conname "$conname ($fmri(conname_real.$i))"
    }
} else {
    set conname "$conname &nbsp;&nbsp;-&nbsp;&nbsp; F${i}"

    set start 1
    for { set c 1 } { $c <= $fmri(ncon_real) } { incr c 1 } {
	if { $fmri(ftest_real${i}.${c}) == 1 } {
	    if { $start == 1 } {
		set conname "$conname ("
		set start 0
	    } else {
		set conname "$conname & "
	    }
	    set conname "${conname}C$c"
	}
    }
    set conname "$conname)"
}

fsl:exec "$FSLDIR/bin/overlay $fmri(rendertype) 0 $underlying -a thresh_$rawstats $fmri(zmin) $fmri(zmax) rendered_thresh_$rawstats"
fsl:exec "${FSLDIR}/bin/slicer rendered_thresh_$rawstats $SLICER 750 rendered_thresh_${rawstats}.png"

if { $firsttime == 1 } {
    fsl:exec "/bin/cp ${FSLDIR}/etc/luts/ramp.gif .ramp.gif"
    feat5:report_insert report_poststats.html poststatsps $ps
    feat5:report_insert report_poststats.html poststatsrs $rs
    feat5:report_insert_start report_poststats.html poststatspics
    fsl:echo report_poststats.html "
<hr><b>Thresholded activation images</b>
&nbsp; &nbsp; &nbsp; &nbsp; 
[ expr int($fmri(zmin)*10)/10.0 ]
<IMG BORDER=0 SRC=\".ramp.gif\">
[ expr int($fmri(zmax)*10)/10.0 ]
$maskcomments
"
    set firsttime 0
}

if { $fmri(thresh) == 3 } {
    fsl:echo report_poststats.html "<p>$conname<br>
    <a href=\"cluster_${rawstats}${STDEXT}.html\"><IMG BORDER=0 SRC=\"rendered_thresh_${rawstats}.png\"></a>
    "
} else {
    fsl:echo report_poststats.html "<p>$conname<br>
    <IMG BORDER=0 SRC=\"rendered_thresh_${rawstats}.png\">
    "
}

#}}}
	}
    }

    feat5:report_insert_stop report_poststats.html poststatspics
}

#}}}
    #{{{ time series plots and report output for each contrast

if { ! $rerunning && $fmri(tsplot_yn) } {
    set fmrifile filtered_func_data
    if { ! [ imtest $fmrifile ] } {
	set fmrifile [ string trimright [ file root ${FD} ] + ]
    }

    new_file tsplot
    fsl:exec "mkdir -p tsplot ; ${FSLDIR}/bin/tsplot . -f $fmrifile -o tsplot"

    catch { exec sh -c "cat tsplot/tsplot_index" } errmsg
    regsub -all "tsplot" $errmsg "tsplot/tsplot" errmsg

    feat5:report_insert report_poststats.html poststatstsplot "<hr><b>Time series plots</b><p>
$errmsg"
}

#}}}
    #{{{ finish up

if { ! $rerunning } {
    feat5:report_insert report_poststats.html poststatsps $ps
    feat5:report_insert report_poststats.html poststatsrs $rs
    fsl:echo report_poststats.html "</BODY></HTML>"
}

return 0

#}}}
}

#}}}
#{{{ feat5:proc_reg

proc feat5:proc_reg { session } {

    #{{{ basic setups

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat5_reg
fsl:echo $logout "</pre><hr>Registration<br><pre>"

fsl:echo report_reg.html "<HTML><HEAD><link REL=\"stylesheet\" TYPE=\"text/css\" href=\".files/fsl.css\">
<TITLE>FSL</TITLE></HEAD><BODY><OBJECT data=\"report.html\"></OBJECT>
<h2>Registration</h2>
<hr><p><b>Analysis methods</b><br>
FMRI data processing was carried out using FEAT (FMRI Expert Analysis Tool) Version $fmri(version), part of FSL (FMRIB's Software Library, www.fmrib.ox.ac.uk/fsl). Registration to high resolution structural and/or standard space images was carried out using FLIRT \[Jenkinson 2001, 2002\]." -o

if { $fmri(regstandard_nonlinear_yn) } {
    fsl:echo report_reg.html "Registration from high resolution structural to standard space was then further refined using FNIRT nonlinear registration \[Andersson 2007a, 2007b\]."
}

fsl:echo report_reg.html "<p><b>References</b><br>
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR00MJ2\">Jenkinson 2001</a>\] M. Jenkinson and S.M. Smith. A Global Optimisation Method for Robust Affine Registration of Brain Images. Medical Image Analysis 5:2(143-156) 2001.<br>
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR02MJ1\">Jenkinson 2002</a>\] M. Jenkinson, P. Bannister, M. Brady and S. Smith. Improved Optimisation for the Robust and Accurate Linear Registration and Motion Correction of Brain Images. NeuroImage 17:2(825-841) 2002.<br>"

if { $fmri(regstandard_nonlinear_yn) } {
    fsl:echo report_reg.html "
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR07JA1\">Andersson 2007a</a>\] J.L.R. Andersson, M. Jenkinson and S.M. Smith. Non-linear optimisation. FMRIB technical report TR07JA1, 2007.<br>
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR07JA2\">Andersson 2007b</a>\] J.L.R. Andersson, M. Jenkinson and S.M. Smith. Non-linear registration, aka Spatial normalisation. FMRIB technical report TR07JA2, 2007.<br>
"
}

fsl:echo report_reg.html "<hr>
<!--regsummarystart-->
<!--regsummarystop-->
"

#}}}

    #{{{ setup varables

set existing_mats 0

new_file reg
fsl:exec "/bin/mkdir -p reg"
cd reg

imcp ../example_func example_func

# test for weighting image from fieldmap unwarping to use with example_func
set ef_weighting_flag ""
if { [ imtest ../unwarp/EF_UD_fmap_sigloss ] } {
    set ef_weighting_flag "-inweight ../unwarp/EF_UD_fmap_sigloss"
}

# test for pre-unwarping example_func image (in order to create unwarping evaluation images)
set doefd 0
if { [ imtest ../example_func_orig_distorted ] } {
    set doefd 1
    imcp ../example_func_orig_distorted example_func_orig_distorted 
}

#}}}
    #{{{ setup initial transforms

set init_initial_highres ""
if { [ file exists $fmri(init_initial_highres) ] } {
    set init_initial_highres "-init $fmri(init_initial_highres)"
}

set init_highres ""
if { [ file exists $fmri(init_highres) ] } {
    set init_highres "-init $fmri(init_highres)"
}

set init_standard ""
if { [ file exists $fmri(init_standard) ] } {
    set init_standard "-init $fmri(init_standard)"
}

#}}}
    #{{{ setup flirt files

if { $fmri(reginitial_highres_yn) } {
    if { [ info exists initial_highres_files($session) ] } {
	fsl:exec "${FSLDIR}/bin/fslmaths [ remove_ext $initial_highres_files($session) ] initial_highres"
    } else { 
	if { ! [ imtest initial_highres ] } {
	    fsl:echo $logout "Warning - registration to initial_highres turned on but
no initial_highres image specified in setup file or in
FEAT directory! Will not register to initial_highres."
	    set fmri(reginitial_highres_yn) 0
	}
    }
}

if { $fmri(reghighres_yn) } {
    if { [ info exists highres_files($session) ] } {
	fsl:exec "${FSLDIR}/bin/fslmaths [ remove_ext $highres_files($session) ] highres"
    } else { 
	if { ! [ imtest highres ] } {
	    fsl:echo $logout "Warning - registration to highres turned on but
no highres image specified in setup file or in
FEAT directory! Will not register to highres."
	    set fmri(reghighres_yn) 0
	}
    }
}

if { $fmri(regstandard_yn) } {
    fsl:exec "${FSLDIR}/bin/fslmaths $fmri(regstandard) standard"

    if { $fmri(regstandard_nonlinear_yn) } {
	set standard_head [ stringstrip $fmri(regstandard) _brain ]
	set highres_head  [ stringstrip $highres_files($session) _brain ]
	if { ! [ imtest $standard_head ] || ! [ imtest $highres_head ] } {
	    set standard_head $fmri(regstandard)
	    set highres_head  $highres_files($session)
	}
	fsl:exec "${FSLDIR}/bin/fslmaths $standard_head standard_head"
	fsl:exec "${FSLDIR}/bin/fslmaths $highres_head  highres_head"

	if { [ imtest $fmri(regstandard)_mask_dil ] } {
	    fsl:exec "${FSLDIR}/bin/fslmaths $fmri(regstandard)_mask_dil standard_mask"
	} else {
	    fsl:exec "${FSLDIR}/bin/fslmaths $fmri(regstandard) -bin -dilF -dilF standard_mask -odt char"
	}
    }
}

#}}}
    #{{{ -> highres

if { $fmri(reghighres_yn) } {

    if { $fmri(reginitial_highres_yn) } {

	feat5:flirt example_func initial_highres $fmri(reginitial_highres_dof) $fmri(reginitial_highres_search) trilinear $existing_mats ${FD}/report_reg.html $init_initial_highres $ef_weighting_flag
	if { $doefd} {
	    feat5:flirt example_func_orig_distorted initial_highres $fmri(reginitial_highres_dof) $fmri(reginitial_highres_search) trilinear $existing_mats "" $init_initial_highres ""
	}

	feat5:flirt initial_highres highres $fmri(reghighres_dof) $fmri(reghighres_search) trilinear $existing_mats ${FD}/report_reg.html $init_highres ""

	fsl:exec "${FSLDIR}/bin/convert_xfm -omat example_func2highres.mat -concat initial_highres2highres.mat example_func2initial_highres.mat"

        feat5:flirt example_func highres 0 0 trilinear 1 ${FD}/report_reg.html "" ""
	if { $doefd } {
	    fsl:exec "${FSLDIR}/bin/convert_xfm -omat example_func_orig_distorted2highres.mat -concat initial_highres2highres.mat example_func_orig_distorted2initial_highres.mat"

	    feat5:flirt example_func_orig_distorted highres 0 0 trilinear 1 ${FD}/report_reg.html "" ""
	}

    } else {

	feat5:flirt example_func highres $fmri(reghighres_dof) $fmri(reghighres_search) trilinear $existing_mats ${FD}/report_reg.html $init_highres $ef_weighting_flag
	if { $doefd} {
	    feat5:flirt example_func_orig_distorted highres $fmri(reghighres_dof) $fmri(reghighres_search) trilinear $existing_mats ${FD}/report_reg.html $init_highres ""
	}

    }
}

#}}}
    #{{{ -> standard

if { $fmri(regstandard_yn) } {

    if { $fmri(reghighres_yn) } {

	feat5:flirt highres standard $fmri(regstandard_dof) $fmri(regstandard_search) trilinear $existing_mats ${FD}/report_reg.html $init_standard ""

	fsl:exec "${FSLDIR}/bin/convert_xfm -omat example_func2standard.mat -concat highres2standard.mat example_func2highres.mat"
        feat5:flirt example_func standard 0 0 trilinear 1 ${FD}/report_reg.html "" ""

	if { $doefd} {
	    fsl:exec "${FSLDIR}/bin/convert_xfm -omat example_func_orig_distorted2standard.mat -concat highres2standard.mat example_func_orig_distorted2highres.mat"
	    feat5:flirt example_func_orig_distorted standard 0 0 trilinear 1 "" "" ""
	}

    } else {

	feat5:flirt example_func standard $fmri(regstandard_dof) $fmri(regstandard_search) trilinear $existing_mats ${FD}/report_reg.html $init_standard $ef_weighting_flag
	if { $doefd} {
	    feat5:flirt example_func_orig_distorted standard $fmri(regstandard_dof) $fmri(regstandard_search) trilinear $existing_mats "" $init_standard ""
	}

    }

    # prepare unwarping evaluation short summary image (example_func vs highres)
    if { $doefd && [ imtest example_func2highres ] } {
	fsl:echo .coord "51 57 40"
	set h [ fsl:exec "${FSLDIR}/bin/img2imgcoord -src standard -dest highres -xfm standard2highres.mat .coord | tail -n 1" ]
	fsl:exec "${FSLDIR}/bin/slicer example_func2highres highres -s 3 -x -[ expr round([ lindex $h 0 ]) ] sla.png -y -[ expr round([ lindex $h 1 ]) ] slb.png -z -[ expr round([ lindex $h 2 ]) ] slc.png"
	fsl:exec "${FSLDIR}/bin/slicer highres example_func2highres -s 3 -x -[ expr round([ lindex $h 0 ]) ] sld.png -y -[ expr round([ lindex $h 1 ]) ] sle.png -z -[ expr round([ lindex $h 2 ]) ] slf.png"
	fsl:exec "${FSLDIR}/bin/pngappend sla.png + sld.png + slb.png + sle.png + slc.png + slf.png example_func2highres3sl.png"
    }
}

#}}}
    #{{{ put biblio stuff & unwarp pic & reg link etc. into original report

cd $FD

if { [ file exists reg/example_func2highres3sl.png ] } {
    feat5:report_insert report_prestats.html unwarphr "<p>Unwarped example_func vs. highres for evaluation of unwarping<br>
<a href=\"reg/index.html\"><IMG BORDER=0 SRC=\"reg/example_func2highres3sl.png\" WIDTH=1000></a><br>"
}

if { [ file exists ${FD}/reg/example_func2standard1.png ] } {
    feat5:report_insert report_reg.html regsummary "<p>Summary registration, FMRI to standard space<br><IMG BORDER=0 SRC=\"reg/example_func2standard1.png\" WIDTH=\"100%\">"
}

#}}}

    #{{{ finish up

fsl:echo report_reg.html "</BODY></HTML>"

return 0

#}}}
}

#}}}
#{{{ feat5:proc_gfeat_setup

proc feat5:proc_gfeatprep { } {

    #{{{ setup

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat2_pre
fsl:echo $logout "</pre><hr>Higher-level input files preparation<br><pre>"

#}}}
    #{{{ fix feat_files and run featregapply

for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    if { $fmri(inputtype) == 2 } {
	set copes($session) $feat_files($session)
	set feat_files($session) [ file dirname [ file dirname $feat_files($session) ] ]
    }
    fsl:exec "${FSLDIR}/bin/featregapply $feat_files($session)"
}

#}}}
    #{{{ setup background image

if { [ file exists $feat_files(1)/design.lev ] } {
    set fmri(bgimage) 3
}

set bg_list ""

switch $fmri(bgimage) {
    1 {
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set find_std [ feat5:find_std $feat_files($session) reg/highres ]
	    if { $find_std != 0 } {
		set bg_list "$bg_list $find_std"
	    }
	}
    }
    2 {
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set find_std [ feat5:find_std $feat_files($session) reg/highres ]
	    if { $find_std != 0 } {
		set bg_list "$bg_list $find_std"
		set session $fmri(multiple)
	    }
	}
    }
    3 {
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set find_std [ feat5:find_std $feat_files($session) example_func ]
	    if { $find_std != 0 } {
		set bg_list "$bg_list $find_std"
	    }
	}
    }
    4 {
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set find_std [ feat5:find_std $feat_files($session) example_func ]
	    if { $find_std != 0 } {
		set bg_list "$bg_list $find_std"
		set session $fmri(multiple)
	    }
	}
    }
}

if { [ string length $bg_list ] == 0 } {
    fsl:exec "${FSLDIR}/bin/fslmaths [ feat5:find_std $feat_files(1) standard ] bg_image"
} else {
    fsl:exec "${FSLDIR}/bin/fslmerge -t bg_image $bg_list"
    if { [ llength $bg_list ] > 1 } {
	fsl:exec "${FSLDIR}/bin/fslmaths bg_image -inm 1000 -Tmean bg_image -odt float"
    }
}

#}}}
    #{{{ setup mask image and inputreg report

set mask_list ""

for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    set mask_list "$mask_list [ feat5:find_std $feat_files($session) mask ]"
}

fsl:exec "${FSLDIR}/bin/fslmerge -t mask $mask_list"

# make input reg report if at second level
if { ! [ file exists $feat_files(1)/design.lev ] } {
    #{{{ create reg images

fsl:exec "mkdir -p inputreg"

cd inputreg

fsl:exec "${FSLDIR}/bin/fslmaths ../mask -mul $fmri(multiple) -Tmean masksum -odt short"
fsl:exec "${FSLDIR}/bin/fslmaths masksum -thr $fmri(multiple) -add masksum masksum"
fsl:exec "$FSLDIR/bin/overlay 0 0 -c ../bg_image -a masksum 0.9 [ expr 2 * $fmri(multiple) ] masksum_overlay"
fsl:exec "${FSLDIR}/bin/slicer masksum_overlay -S 2 750 masksum_overlay.png"
#imrm masksum_overlay

fsl:exec "${FSLDIR}/bin/fslmaths masksum -mul 0 maskunique"
for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    fsl:exec "${FSLDIR}/bin/fslmaths [ feat5:find_std $feat_files($session) mask ] -mul -1 -add 1 -mul $session -add maskunique maskunique"
}
fsl:exec "${FSLDIR}/bin/fslmaths masksum -thr [ expr $fmri(multiple) - 1 ] -uthr [ expr $fmri(multiple) - 1 ] -bin -mul maskunique maskunique"
fsl:exec "$FSLDIR/bin/overlay 0 0 ../bg_image -a maskunique 0.9 $fmri(multiple) maskunique_overlay"
fsl:exec "${FSLDIR}/bin/slicer maskunique_overlay -S 2 750 maskunique_overlay.png"
#imrm maskunique_overlay

cd $FD

#}}}
    #{{{ create reg webpage

fsl:exec "/bin/cp ${FSLDIR}/etc/luts/ramp.gif .ramp.gif"

fsl:echo report_reg.html "<hr><p><b>Summaries of functional-to-standard registrations for all inputs</b>
"

for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
    # use new format web reports if they exist, otherwise assume old format web report
    if { [ file exists $feat_files($i)/report_reg.html ] } {
	fsl:echo report_reg.html "<p>${i} <A HREF=\"$feat_files($i)/report_reg.html\">$feat_files($i)<br>
<IMG BORDER=0 SRC=\"$feat_files($i)/reg/example_func2standard1.png\" width=\"100%\"></A>
"
    } else {
	fsl:echo report_reg.html "<p>${i} <A HREF=\"$feat_files($i)/reg/index.html\">$feat_files($i)<br>
<IMG BORDER=0 SRC=\"$feat_files($i)/reg/example_func2standard1.gif\" width=\"100%\"></A>
"
    }
}

fsl:echo report_reg.html "<hr><p><b>Sum of all input masks after transformation to standard space
&nbsp; &nbsp; &nbsp; &nbsp; 1 <IMG BORDER=0 SRC=\".ramp.gif\"> $fmri(multiple)</b>
<br><IMG BORDER=0 SRC=\"inputreg/masksum_overlay.png\">
<hr><p><b>Unique missing-mask voxels
&nbsp; &nbsp; &nbsp; &nbsp; 1 <IMG BORDER=0 SRC=\".ramp.gif\"> $fmri(multiple)</b>
<br>This shows voxels where only one mask is missing, to enable easy identification of single gross registration problems.
For detail, view image ${FD}/inputreg/maskunique
<br><IMG BORDER=0 SRC=\"inputreg/maskunique_overlay.png\">
</BODY></HTML>
"

#}}}
}

fsl:exec "${FSLDIR}/bin/fslmaths mask -Tmin mask"

#}}}
    #{{{ setup mean_func image

set mean_list ""

for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    set find_std [ feat5:find_std $feat_files($session) mean_func ]
    if { $find_std != 0 } {
	set mean_list "$mean_list $find_std"
    }
}

if { [ string length $mean_list ] == 0 } {
    fsl:exec "${FSLDIR}/bin/fslmaths mask -bin -mul 10000 mean_func -odt float"
} else {
    fsl:exec "${FSLDIR}/bin/fslmerge -t mean_func $mean_list"
    fsl:exec "${FSLDIR}/bin/fslmaths mean_func -Tmean mean_func"
}

#}}}

    if { $fmri(inputtype) == 1 } {
	#{{{ create 4D inputs for "FEAT directories" option

for { set nci 1 } { $nci <=  $fmri(ncopeinputs) } { incr nci 1 } {   

    if { $fmri(copeinput.$nci) } {

	set cope_list ""
	set mean_lcon 0
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set find_std [ feat5:find_std $feat_files($session) stats/cope$nci ]
	    if { $find_std != 0 } {
		set cope_list "$cope_list $find_std"
	    } else {
		fsl:echo $logout "Error - not all input FEAT directories have the same set of contrasts! (currently looking in $feat_files($session) for cope${nci})"
	        exit 1
            }
	    if { [ file exists $feat_files($session)/design.con ] } {
		set awknum [ expr 1 + $nci ]
		set mean_lcon_incr [ exec sh -c "grep PPheights $feat_files($session)/design.con | awk '{ print \$$awknum }'" ]
		if { [ file exists $feat_files($session)/design.lcon ] } {
		    set mean_lcon_incr [ expr $mean_lcon_incr * [ exec sh -c "cat $feat_files($session)/design.lcon" ] ]
		}
		if { [ string length $mean_lcon_incr ] == 0 } {
		    fsl:echo $logout "Error - not all input FEAT directories have valid and compatible design.con contrast files."
		    exit 1
		}
		set mean_lcon [ expr $mean_lcon + $mean_lcon_incr ]
	    } else {
		fsl:echo $logout "Error - not all input FEAT directories have valid and compatible design.con contrast files."
		return 1
	    }
        }

	fsl:exec "${FSLDIR}/bin/fslmerge -t cope$nci $cope_list"
	fsl:exec "${FSLDIR}/bin/fslmaths cope$nci -mas mask cope$nci"

	set mean_lcon [ expr $mean_lcon / $fmri(multiple) ]
	if { $mean_lcon < 0.01 } {
	    set mean_lcon 1
	}
	fsl:exec "printf '$mean_lcon ' >> design.lcon"

	set varcope_list ""
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    set varcope_list "$varcope_list [ feat5:find_std $feat_files($session) stats/varcope$nci ]"
	}
	fsl:exec "${FSLDIR}/bin/fslmerge -t varcope$nci $varcope_list"
	fsl:exec "${FSLDIR}/bin/fslmaths varcope$nci -mas mask varcope$nci"
	
	#{{{ setup t_dof

	set tdof_list ""
	for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	    if { $fmri(mixed_yn) != 3 || [ file exists $feat_files($session)/design.lev ] } {
		set find_std [ feat5:find_std $feat_files($session) stats/tdof_t$nci ]
		if { $find_std != 0 } {
		    set tdof_list "$tdof_list $find_std"
		}
	    } else {
		set THEDOF [ exec sh -c "cat $feat_files($session)/stats/dof" ]
		fsl:exec "${FSLDIR}/bin/fslmaths $feat_files($session)/reg_standard/stats/cope$nci -mul 0 -add $THEDOF $feat_files($session)/reg_standard/stats/FEtdof_t$nci"
		set tdof_list "$tdof_list $feat_files($session)/reg_standard/stats/FEtdof_t$nci"
	    }
	}
	if { $tdof_list != "" } {
	    fsl:exec "${FSLDIR}/bin/fslmerge -t tdof_t$nci $tdof_list"
	    fsl:exec "${FSLDIR}/bin/fslmaths tdof_t$nci -mas mask tdof_t$nci"
	}

#}}}

    } else {
	fsl:exec "printf '1 ' >> design.lcon"
    }
}

#}}}
    } elseif { $fmri(inputtype) == 2 } {
	#{{{ create 4D inputs for "3D cope input" option

set cope_list ""
set varcope_list ""
set tdof_list ""
set mean_lcon 0

for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    set copename [ file tail $copes($session) ]
    set copenumber [ remove_ext [ string trimleft $copename "cope" ] ]

    set cope_list "$cope_list [ feat5:find_std $feat_files($session) stats/$copename ]"
    set varcope_list "$varcope_list [ feat5:find_std $feat_files($session) stats/var$copename ]"

    if { [ file exists $feat_files($session)/design.con ] } {
	set awknum [ expr 1 + $copenumber ]
	set mean_lcon_incr [ exec sh -c "grep PPheights $feat_files($session)/design.con | awk '{ print \$$awknum }'" ]
	if { [ file exists $feat_files($session)/design.lcon ] } {
	    set mean_lcon_incr [ expr $mean_lcon_incr * [ exec sh -c "cat $feat_files($session)/design.lcon" ] ]
	}
	set mean_lcon [ expr $mean_lcon + $mean_lcon_incr ]
    }

    if { $fmri(mixed_yn) != 3 || [ file exists $feat_files(1)/design.lev ] } {
	set find_std [ feat5:find_std $feat_files($session) stats/tdof_t$copenumber ]
	if { $find_std != 0 } {
	    set tdof_list "$tdof_list $find_std"
	}
    } else {
	set THEDOF [ exec sh -c "cat $feat_files($session)/stats/dof" ]
	fsl:exec "${FSLDIR}/bin/fslmaths $feat_files($session)/reg_standard/stats/$copename -mul 0 -add $THEDOF $feat_files($session)/reg_standard/stats/FEtdof_t${copenumber}"
	set tdof_list "$tdof_list $feat_files($session)/reg_standard/stats/FEtdof_t${copenumber}"
    }
}

fsl:exec "${FSLDIR}/bin/fslmerge -t cope1 $cope_list"
fsl:exec "${FSLDIR}/bin/fslmaths cope1 -mas mask cope1"

set mean_lcon [ expr $mean_lcon / $fmri(multiple) ]
if { $mean_lcon < 0.01 } {
    set mean_lcon 1
}
fsl:exec "echo $mean_lcon > design.lcon"

fsl:exec "${FSLDIR}/bin/fslmerge -t varcope1 $varcope_list"
fsl:exec "${FSLDIR}/bin/fslmaths varcope1 -mas mask varcope1"

if { $tdof_list != "" } {
    fsl:exec "${FSLDIR}/bin/fslmerge -t tdof_t1 $tdof_list"
    fsl:exec "${FSLDIR}/bin/fslmaths tdof_t1 -mas mask tdof_t1"
}

#}}}
    }

    #{{{ featregapply cleanup

if { $fmri(sscleanup_yn) } {
    for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
	fsl:exec "${FSLDIR}/bin/featregapply $feat_files($session) -c"
    }
}

#}}}

    return 0
}

#}}}
#{{{ feat5:proc_flame1,2,3

proc feat5:proc_flame1 { session } {
    #{{{ basic setups

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat3a_flame
fsl:echo $logout "</pre><hr>Higher-level stats<br><pre>"

fsl:echo report_stats.html "<HTML><HEAD><link REL=\"stylesheet\" TYPE=\"text/css\" href=\".files/fsl.css\">
<TITLE>FSL</TITLE></HEAD><BODY><OBJECT data=\"report.html\"></OBJECT>
<h2>Stats</h2>
<!--statspsstart-->
<!--statspsstop-->
<!--statsrsstart-->
<!--statsrsstop-->" -o

if { [ file exists design.png ] } {
    fsl:echo report_stats.html "<hr><p><b>Design matrix</b><br><a href=\"design.mat\"><IMG BORDER=0 SRC=\"design.png\"></a>"
    if { [ file exists design_cov.png ] } {
	fsl:echo report_stats.html "<p><b>Covariance matrix & design efficiency</b><br><IMG BORDER=0 SRC=\"design_cov.png\">"
    }
}

set ps "<hr><p><b>Analysis methods</b><br>FMRI data processing was carried out using FEAT (FMRI Expert Analysis Tool) Version $fmri(version), part of FSL (FMRIB's Software Library, www.fmrib.ox.ac.uk/fsl)."
set rs ""

#}}}
    #{{{ FLAME1

fsl:exec "cat ../design.lcon | awk '{ print \$$session }' > design.lcon"

imcp ../bg_image example_func
imcp ../mean_func mean_func
imcp ../mask mask

set funcdata [ feat5:strip [ file tail $FD ] ]
immv ../$funcdata filtered_func_data
immv ../var$funcdata var_filtered_func_data

set DOFS ""
set thetdof ../tdof_t[ string trimleft $funcdata "cope" ]
if { [ imtest $thetdof ] } {
    immv $thetdof tdof_filtered_func_data
    if { [ exec sh -c "${FSLDIR}/bin/fslnvols tdof_filtered_func_data 2> /dev/null" ] == $fmri(npts) } {
	set DOFS "--dvc=tdof_filtered_func_data"
    }
}

set FLAME ""
if { [ file exists design.fts ] } {
    set FLAME "--fc=design.fts"
}

set ROBUST ""
if { $fmri(robust_yn) && $fmri(mixed_yn) != 3 } {
    set FLAME "$FLAME --io"
    set ROBUST " with automatic outlier detection \[Woolrich 2008\]"
} else {
    set fmri(robust_yn) 0
}

set ps "$ps Higher-level analysis was carried out using"
switch $fmri(mixed_yn) {
    0 {
	set FLAME "$FLAME --runmode=ols"
	set ps "$ps OLS (ordinary least squares) simple mixed effects${ROBUST}."
    }
    1 {
	if { $fmri(thresh) == 3 } {
	    set zlt [ expr $fmri(z_thresh) - 0.05 ]
	    set zut [ expr $fmri(z_thresh) + 0.35 ]
	} else {
	    set zlt 2
	    set zut 20
	}
	set FLAME "$FLAME --runmode=flame12 --nj=10000 --bi=500 --se=1 --fm --zlt=$zlt --zut=$zut"
	set ps "$ps FLAME (FMRIB's Local Analysis of Mixed Effects) stage 1 and stage 2${ROBUST} \[Beckmann 2003, Woolrich 2004, Woolrich 2008\]."
    }
    2 {
	set FLAME "$FLAME --runmode=flame1"
	set ps "$ps FLAME (FMRIB's Local Analysis of Mixed Effects) stage 1${ROBUST} \[Beckmann 2003, Woolrich 2004, Woolrich 2008\]."
    }
    3 {
	set FLAME "$FLAME --runmode=fe"
	set ps "$ps a fixed effects model, by forcing the random effects variance to zero in FLAME (FMRIB's Local Analysis of Mixed Effects) \[Beckmann 2003, Woolrich 2004, Woolrich 2008\]."
    }
}

if { $fmri(evs_vox) > 0 } {
    set EVNUMS [ expr 1 + $fmri(evs_real) - $fmri(evs_vox) ]
    set EVNAMES "$fmri(evs_vox_1)"
    for { set f 2 } { $f <= $fmri(evs_vox) } { incr f 1 } {
	set EVNUMS "${EVNUMS},[ expr $f + $fmri(evs_real) - $fmri(evs_vox) ]"
	set EVNAMES "${EVNAMES},$fmri(evs_vox_$f)"
    }
    set FLAME "$FLAME --voxelwise_ev_numbers=${EVNUMS} --voxelwise_ev_filenames=${EVNAMES}"
}

    set rs "<p><b>References</b><br>
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR01CB1\">Beckmann 2003</a>\] C. Beckmann, M. Jenkinson and S.M. Smith. General multi-level linear modelling for group analysis in FMRI. NeuroImage 20(1052-1063) 2003.<br>
\[<a href=\"http://www.fmrib.ox.ac.uk/analysis/techrep/#TR03MW1\">Woolrich 2004</a>\] M.W. Woolrich, T.E.J Behrens, C.F. Beckmann, M. Jenkinson and S.M. Smith. Multi-level linear modelling for FMRI group analysis using Bayesian inference. NeuroImage 21:4(1732-1747) 2004<br>
\[Woolrich 2008\] M.W. Woolrich. Robust Group Analysis Using Outlier Inference. NeuroImage 41:2(286-301) 2008<br>
"


set NumPoints [ exec sh -c "grep NumPoints design.mat | awk '{ print \$2 }'" ]
set NumWaves  [ exec sh -c "grep NumWaves  design.mat | awk '{ print \$2 }'" ]

fsl:exec "/bin/rm .flame ; touch .flame ; chmod a+x .flame" -n

if { $NumPoints < 30 && $fmri(mixed_yn) != 1 && $fmri(robust_yn) == 0 } {
    fsl:echo .flame "$FSLDIR/bin/flameo --cope=filtered_func_data --vc=var_filtered_func_data $DOFS --mask=mask --ld=stats --dm=design.mat --cs=design.grp --tc=design.con $FLAME"
} else {

    fsl:exec "$FSLDIR/bin/fslsplit mask tmpmask -z"
    fsl:exec "$FSLDIR/bin/fslsplit filtered_func_data tmpcope -z"
    fsl:exec "$FSLDIR/bin/fslsplit var_filtered_func_data tmpvarcope -z"
    if { $fmri(evs_vox) > 0 } {
	set evnn 1
	foreach evn [ string map {, " "} $EVNAMES ] {
	    fsl:exec "$FSLDIR/bin/fslsplit $evn tmpvoxev${evnn}_ -z"
	    incr evnn 1
	}
    }
    if { [ imtest tdof_filtered_func_data ] } {
	fsl:exec "$FSLDIR/bin/fslsplit tdof_filtered_func_data tmptdof -z"
    }

    set DIMZ [ exec sh -c "$FSLDIR/bin/fslval example_func dim3" ]
    for { set slice 0 } { $slice < $DIMZ } { incr slice 1 } {
        set pad [ format %04d $slice ]
	set DOFS ""
	if { [ imtest tdof_filtered_func_data ] } {
	    set DOFS "--dvc=tmptdof$pad"
	}
	set FLAMEp $FLAME
	if { $fmri(evs_vox) > 0 } {
	    set evnn 1
	    foreach evn [ string map {, " "} $EVNAMES ] {
		regsub $evn $FLAMEp tmpvoxev${evnn}_$pad FLAMEp
	        incr evnn 1
	    }
	}
	fsl:echo .flame "$FSLDIR/bin/flameo --cope=tmpcope$pad --vc=tmpvarcope$pad $DOFS --mask=tmpmask$pad --ld=stats$pad --dm=design.mat --cs=design.grp --tc=design.con $FLAMEp"
    }
}

fsl:echo $logout [ exec sh -c "cat .flame | head -n 1" ]

fsl:echo dof "[ expr $NumPoints - $NumWaves ]"
new_file stats

#}}}
    #{{{ finish up

feat5:report_insert report_stats.html statsps $ps
feat5:report_insert report_stats.html statsrs $rs

fsl:echo report_stats.html "</BODY></HTML>"

return 0

#}}}
}

proc feat5:proc_flame2 { } {
    #{{{ basic setups

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat3b_flame

#}}}
    fsl:exec "sh ./.flame"
    return 0
}

proc feat5:proc_flame3 { } {
    #{{{ basic setups

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/feat3c_flame

#}}}
    #{{{ FLAME3

if { [ file exists stats0000 ] } {
    foreach f [ imglob -extension stats0000/* ] {
	set froot [ file tail $f ]
	fsl:exec "$FSLDIR/bin/fslmerge -z stats0000/$froot [ lsort -dictionary [ imglob stats*/$froot ] ]"
    }
    fsl:exec "/bin/mv stats0000 stats ; /bin/rm -rf stats?* tmp*"
}

fsl:exec "/bin/rm -f stats/zem* stats/zols* stats/mask* ; /bin/mv dof stats"

if { [ imtest stats/res4d ] } {
    fsl:exec "$FSLDIR/bin/smoothest -d [ exec sh -c "cat stats/dof" ] -m mask -r stats/res4d > stats/smoothness"
}

#}}}
    return 0
}

#}}}
#{{{ feat5:proc_gica

proc feat5:proc_gica { } {

    #{{{ setup

global FSLDIR FSLSLASH PWD HOME HOSTNAME OSFLAVOUR logout fmri feat_files unwarp_files unwarp_files_mag initial_highres_files highres_files FD report ps rs comout gui_ext FSLPARALLEL

cd $fmri(outputdir)
set FD [ pwd ]

set logout ${FD}/logs/gica
fsl:echo $logout "</pre><hr>Higher-level MELODIC<br><pre>"

#}}}
    #{{{ fix feat_files and run featregapply

for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    fsl:exec "${FSLDIR}/bin/featregapply $feat_files($session)"
    fsl:echo report_firstlevel.html "${session} <A HREF=\"$feat_files($session)/report_prestats.html\">$feat_files($session)</A><br>"
}
fsl:echo report_firstlevel.html "</BODY></HTML>"

#}}}
    #{{{ setup background and mask images

set bg_list ""
set mask_list ""
for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    set bg_list "$bg_list $feat_files($session)/reg_standard/bg_image"
    set mask_list "$mask_list $feat_files($session)/reg_standard/mask"
}

fsl:exec "${FSLDIR}/bin/fslmerge -t bg_image $bg_list"
fsl:exec "${FSLDIR}/bin/fslmaths bg_image -inm 1000 -Tmean bg_image -odt float"

#}}}
    #{{{ setup mask image and inputreg report

fsl:exec "${FSLDIR}/bin/fslmerge -t mask $mask_list"

#{{{ create reg images

fsl:exec "mkdir -p inputreg"

cd inputreg

fsl:exec "${FSLDIR}/bin/fslmaths ../mask -mul $fmri(multiple) -Tmean masksum -odt short"
fsl:exec "${FSLDIR}/bin/fslmaths masksum -thr $fmri(multiple) -add masksum masksum"
fsl:exec "$FSLDIR/bin/overlay 0 0 -c ../bg_image -a masksum 0.9 [ expr 2 * $fmri(multiple) ] masksum_overlay"
fsl:exec "${FSLDIR}/bin/slicer masksum_overlay -S 2 750 masksum_overlay.png"
#imrm masksum_overlay

fsl:exec "${FSLDIR}/bin/fslmaths masksum -mul 0 maskunique"
for { set session 1 } { $session <= $fmri(multiple) } { incr session 1 } {
    fsl:exec "${FSLDIR}/bin/fslmaths [ feat5:find_std $feat_files($session) mask ] -mul -1 -add 1 -mul $session -add maskunique maskunique"
}
fsl:exec "${FSLDIR}/bin/fslmaths masksum -thr [ expr $fmri(multiple) - 1 ] -uthr [ expr $fmri(multiple) - 1 ] -bin -mul maskunique maskunique"
fsl:exec "$FSLDIR/bin/overlay 0 0 ../bg_image -a maskunique 0.9 $fmri(multiple) maskunique_overlay"
fsl:exec "${FSLDIR}/bin/slicer maskunique_overlay -S 2 750 maskunique_overlay.png"
#imrm maskunique_overlay

cd $FD

#}}}
#{{{ create reg webpage

fsl:exec "/bin/cp ${FSLDIR}/etc/luts/ramp.gif .ramp.gif"

fsl:echo report_reg.html "<hr><p><b>Summaries of functional-to-standard registrations for all inputs</b>
"

for { set i 1 } { $i <= $fmri(multiple) } { incr i 1 } {
    # use new format web reports if they exist, otherwise assume old format web report
    if { [ file exists $feat_files($i)/report_reg.html ] } {
	fsl:echo report_reg.html "<p>${i} <A HREF=\"$feat_files($i)/report_reg.html\">$feat_files($i)<br>
<IMG BORDER=0 SRC=\"$feat_files($i)/reg/example_func2standard1.png\" width=\"100%\"></A>
"
    } else {
	fsl:echo report_reg.html "<p>${i} <A HREF=\"$feat_files($i)/reg/index.html\">$feat_files($i)<br>
<IMG BORDER=0 SRC=\"$feat_files($i)/reg/example_func2standard1.gif\" width=\"100%\"></A>
"
    }
}

fsl:echo report_reg.html "<hr><p><b>Sum of all input masks after transformation to standard space
&nbsp; &nbsp; &nbsp; &nbsp; 1 <IMG BORDER=0 SRC=\".ramp.gif\"> $fmri(multiple)</b>
<br><IMG BORDER=0 SRC=\"inputreg/masksum_overlay.png\">
<hr><p><b>Unique missing-mask voxels
&nbsp; &nbsp; &nbsp; &nbsp; 1 <IMG BORDER=0 SRC=\".ramp.gif\"> $fmri(multiple)</b>
<br>This shows voxels where only one mask is missing, to enable easy identification of single gross registration problems.
For detail, view image ${FD}/inputreg/maskunique
<br><IMG BORDER=0 SRC=\"inputreg/maskunique_overlay.png\">
</BODY></HTML>
"

#}}}

fsl:exec "${FSLDIR}/bin/fslmaths mask -Tmin -bin mask -odt char"

#}}}
    #{{{ MELODIC

set thecommand "${FSLDIR}/bin/melodic -i .filelist -o groupmelodic.ica -v --nobet --bgthreshold=$fmri(brain_thresh) --tr=$fmri(tr) --report --guireport=../../report.html --bgimage=bg_image"

if { $fmri(dim_yn) == 1 } {
    set thecommand "$thecommand -d 0"
} else {
    set thecommand "$thecommand -d $fmri(dim)"
}

if { $fmri(varnorm) == 0 } {
    set thecommand "$thecommand --vn"
}

if { $fmri(thresh_yn) == 0 } {
    set thecommand "$thecommand --no_mm"
} else {
    set thecommand "$thecommand --mmthresh=\"$fmri(mmthresh)\""
}

if { $fmri(ostats) == 1 } {
    set thecommand "$thecommand --Ostats"
}

if { $fmri(icaopt) == 2 } {
    set thecommand "$thecommand -a concat"
} else {
    set thecommand "$thecommand -a tica"
}

if { [ file exists $fmri(ts_model_mat) ] && [ file exists $fmri(ts_model_con) ] } {
    set thecommand "$thecommand --Tdes=$fmri(ts_model_mat) --Tcon=$fmri(ts_model_con)"
}

if { [ file exists $fmri(subject_model_mat) ] && [ file exists $fmri(subject_model_con) ] } {
    set thecommand "$thecommand --Sdes=$fmri(subject_model_mat) --Scon=$fmri(subject_model_con)"
}

fsl:exec "$thecommand"

#}}}

    return 0
}

#}}}
#{{{ feat5:proc_stop

proc feat5:proc_stop { } {
    
    global fmri

    cd $fmri(outputdir)

    cd logs
    feat5:report_insert feat0 refresh ""

    cd $fmri(outputdir)

    catch { exec sh -c "grep -i '\<error\>' logs/* | wc -l" } errorCount 
    catch { exec sh -c "cat logs/* > report_log.html" } putserr

    if { $errorCount == 0 } { feat5:report_insert report.html running "Finished at [exec date]" } else {
	feat5:report_insert report.html running "Finished at [exec date]<br/><font size=+2><font color=\"red\">Errors occured during the analysis</font></font>" }


    return 0
}

#}}}

