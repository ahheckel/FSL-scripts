h2. FSL-scripts

Script-framework using FSL, Freesurfer and AFNI functionality for automatization and high-throughput processing of MRI data in clustered environments.

h3. Features

* Full automated cascades leading to 2nd level GLM stats for cross-sectional and longitudinal designs  
* Functional analyses  
** FSL's Independent Component Analysis (Melodic-ICA)  
** FSL's Dual Regression  
** FSL's Network analysis (FSLNets)  
** Amplitute of Low Frequency Fluctuations (ALFF)  
** fractional Amplitute of Low Frequency Fluctuations (fALFF)  
* Structural analyses  
** FSL's Tract-Based Spatial Statistics (TBSS)
** FSL's Tract-Based Spatial Statistics (crossing fibres) (TBSSX)
** FSL's Voxel-Based Morphometry (VBM)
** Freesurfer cross-sectional / longitudinal streams
** Freesurfer's TRActs Constrained by UnderLying Anatomy (TRACULA)
** Freesurfer's cortical thickness analysis
* Cluster engines are addressed via FSL's fsl_sub
* Processing of intermediate files in node's local /tmp to minimize network traffic
* Nautilus scripts for easy viewing

h3. Requirements

* Linux (CentOS5 or compatible)
* Bash > 3.2.25 
* FSL > 4.9.1 / 5.0
* Freesurfer > 5.1.0
* SunGridEngine > 6.1u6
* Octave > 3.0.5
* Gnome > 2.32
* ImageMagick > 6.7.5-3 (optional)

h3. Usage

* Create study-directory.
* Copy and edit ./globalvars global configuration file.
* Arrange *.nii.gz files in input directory (./src).
* Define GLMs for each module (./grp/GLM).
* Edit config* files in ./subj (if settings differ across subjects/sessions).
* Run ./go.sh to start processing.

```
my-study              study-directory
  |
  |-rsc               symlink to /FSL-scripts/rsc
  |-src               data directory containing unprocessed nii.gz files
  |  |-01             subject 01
  |  |  |-a           session a
  |  |  |-b           session b
  |  |-02             subject 02
  |  |  |_a           session a
  |  |  |_b           session b
  |  ... ...
  |_subj              1st level processing
  |  |
  |  config_*         files containing per-subject/session preprocessing settings deviating from 'globalvars'
  |  |_01             subject 01
  |  |  |_a           session a
  |  |    |_alff      alff processing
  |  |    |_bold      bold processing
  |  |    |_bpx       bedpostx processing
  |  |    |_fdt       dwi processing
  |  |    |_fm        fieldmap processing
  |  |    |_topup     dwi processing using topup
  |  |    |_vbm       vbm processing
  |  ...
  |  |_FS_subj        Freesurfer subjects' directory
  |      |_01a        subject 01, session a
  |      |_01b        subject 01, session b
  |      ...
  |      |_02a        subject 02, session a
  |      |_02b        subject 02, session b
  |      ...
  |_grp               2nd level processing
  |  |_GLM            General linear models (defined using FSL's'Glm')
  |  |  |_alff      
  |  |  |_dualreg
  |  |  |_fslnets
  |  |  |_FS_stats
  |  |  |_tbss
  |  |  |_vbm
  |  |
  |  |_alff           2nd level processing of alff incl. GLM results
  |  |_dualreg        2nd level processing of dual-regression incl. GLM results
  |  |_fslnets        2nd level processing of FSLNets incl. GLM results
  |  |_FS_stats       2nd level processing of cortical thickness incl. GLM results
  |  |_melodic        ICA decomposition
  |  |_tbss           2nd level processing of tbss(x) incl. GLM results
  |  |_vbm            2nd level processing of vbm incl. GLM results
  |      
  globalvars          global configuration file
  run_scripts.sh      link to ./rsc/main.sh
  go.sh               start processing on cluster as background task
```  
 
h3. Status

Alpha

h3. Contact

Dr. Andi Heckel, M.Sc.
University of Heidelberg
Department of Neuroradiology
heckelandreas@googlemail.com

h3. Links

FSL http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/
Freesurfer http://surfer.nmr.mgh.harvard.edu/fswiki
TRACULA http://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/Tracula
1000FunctionalConnectomes http://www.nitrc.org/projects/fcon_1000/
MRIConvert http://lcni.uoregon.edu/~jolinda/MRIConvert/
ImageMagick http://www.imagemagick.org/script/index.php
FSL-compatible-transformation-matrix http://www.mathworks.es/matlabcentral/fileexchange/30804-make-fsl-compatible-transformation-matrix


