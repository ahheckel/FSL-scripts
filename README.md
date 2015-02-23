## FSL-scripts

Script-framework using FSL, Freesurfer and AFNI functionality for automatization and high-throughput processing of MRI data in clustered environments.
This work was supported by the PostDoc Programme of the Medical Faculty (University of Heidelberg).

### Features
* Fully automated cascades up to 2nd-level GLM stats for cross-sectional and longitudinal designs  
* Functional analyses  
    - FSL's Independent Component Analysis (Melodic-ICA)  
    - FSL's Dual Regression  
    - FSL's Network analysis (FSLNets v0.3)  
    - Amplitute of Low Frequency Fluctuations (ALFF)  
    - fractional Amplitute of Low Frequency Fluctuations (fALFF)  
* Structural analyses  
    - FSL's Tract-Based Spatial Statistics (TBSS)  
    - FSL's Tract-Based Spatial Statistics (crossing fibres) (TBSSX)  
    - FSL's Voxel-Based Morphometry (VBM)  
    - FSL's AutoPtx (v0.0.1)
    - Freesurfer cross-sectional / longitudinal streams  
    - Freesurfer's TRActs Constrained by UnderLying Anatomy (TRACULA)  
    - Freesurfer's cortical thickness analysis  
* Cluster engines are addressed via FSL's fsl_sub  
* Processing of intermediate files in node's local /tmp to minimize network traffic  
* Nautilus scripts for easy viewing  

### Requirements
* Linux 
* Bash >=4
* FSL > 4.9.1 
* Freesurfer > 5.1.0 
* SunGridEngine > 6.1u6  
* Octave > 3.0.5  
* Gnome > 2.32  
* ImageMagick > 6.7.5-3 (optional)  

### Installation
* Download and unpack zip-file.
* Export installation directory and mount on all nodes.
* run ```./rsc/check_compatibility.sh``` to check  whether files of existing  
FSL/Freesurfer installations differ from what is expected by this framework.
* run ```./rsc/update.sh [32|64]```

### Usage
* Create study-directory.  
* Copy and edit global settings in ./globalvars ,  
  where processing settings, acquisition parameters, directory structure,  
  naming of subjects/sessions and input files are defined.  
* Arrange *.nii.gz files in input directory (./src).  
* Define GLMs for each module using FSL's Glm (./grp/GLM).  
  For Freesurfer stats see https://surfer.nmr.mgh.harvard.edu/fswiki/FsgdExamples and  
                           https://surfer.nmr.mgh.harvard.edu/fswiki/RepeatedMeasuresAnova
* Copy and edit config* files in ./subj (if preprocessing settings  
  and/or acquisition parameters vary across subjects/sessions).  
* Run ```./run_script.sh [bg]``` to start processing.  


Example directory structure:  

```
my-study              study-directory
  |
  |-rsc               symlink to /FSL-scripts/rsc
  |-src               data directory containing unprocessed nii.gz files
  |  |-01             subject 01
  |  | |-a            session a
  |  | | |-*.nii.gz   input nifti files (t1,bold,dwi with bvals/bvecs,fieldmap magn/phase)
  |  | |-b            session b
  |  | ...
  |  |-02             subject 02
  |  | |-a            session a
  |  | |-b            session b
  |  .....
  |-subj              1st-level processing
  |  |-config_*       files with per-subject/session pre-proc. settings deviating from 'globalvars'
  |  |-01             subject 01
  |  | |-a            session a
  |  | | |-alff       output of alff processing
  |  | | |-bold       output of bold processing
  |  | | |-bpx        output of bedpostx processing
  |  | | |-fdt        output of dwi processing
  |  | | |-fm         output of fieldmap processing
  |  | | |-topup      output of dwi processing using topup
  |  | | |-vbm        output of vbm processing
  |  | | 
  |  | |-b            session b
  |  .....
  |  |-FS_subj        Freesurfer subjects' directory
  |    |-01a          subject 01, session a
  |    |-01b          subject 01, session b
  |    ...
  |    |-02a          subject 02, session a
  |    |-02b          subject 02, session b
  |    ...
  |-grp               2nd-level processing
  |  |-GLM            General linear models
  |  | |-alff
  |  | | |-glm01      alff GLM 01
  |  | | |-glm02      alff GLM 02
  |  | | | |-design.con
  |  | | | |-design.fts
  |  | | | |-design.mat
  |  | | | |-design.grp
  |  | | | |-design.fsf
  |  | | |
  |  | | ...
  |  | |-dualreg
  |  | |-fslnets
  |  | |-FS_stats
  |  | |-tbss
  |  | |-vbm
  |  |
  |  |-alff           output of 2nd-level processing of alff incl. GLM results
  |  |-dualreg        output of 2nd-level processing of dual-regression incl. GLM results
  |  |-fslnets        output of 2nd-level processing of FSLNets incl. GLM results
  |  |-FS_stats       output of 2nd-level processing of cortical thickness incl. GLM results
  |  |-melodic        output of ICA decomposition
  |  |-tbss           output of 2nd-level processing of tbss(x) incl. GLM results
  |  |-vbm            output of 2nd-level processing of vbm incl. GLM results
  |      
  |-globalvars        global configuration file
  |-run_scripts.sh    symlink to ./rsc/main.sh
```  
 
### Status
Alpha

### Contact
Dr. Andi Heckel, M.Sc.  
University of Heidelberg  
Department of Neuroradiology  
heckelandreas@googlemail.com  

### Links
FSL http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/  
Freesurfer http://surfer.nmr.mgh.harvard.edu/fswiki  
TRACULA http://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/Tracula  
1000FunctionalConnectomes http://www.nitrc.org/projects/fcon_1000/  
MRIConvert http://lcni.uoregon.edu/~jolinda/MRIConvert/  
ImageMagick http://www.imagemagick.org/script/index.php  
FSL-compatible-transformation-matrix http://www.mathworks.es/matlabcentral/fileexchange/30804-make-fsl-compatible-transformation-matrix  


