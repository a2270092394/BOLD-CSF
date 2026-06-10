# BOLD-CSF coupling pipeline

This repository contains MATLAB and WSL/FSL scripts for extracting cortical BOLD and CSF time series and calculating BOLD-CSF coupling from resting-state fMRI data.

## Overview

The primary BOLD-CSF coupling metric used for downstream statistical analyses is calculated from the cross-correlation between the original cortical BOLD signal and the CSF signal. The negative first-order derivative analysis is provided as an auxiliary validation step and is not used for primary group comparison, correlation, Cox regression, or mediation analyses unless explicitly specified by the user.

## Software requirements

- MATLAB with Image Processing Toolbox functions such as `niftiread`, `niftiinfo`, and `imresize3`
- SPM12
- FSL, run under WSL/Linux for the shell script
- DPARSF/DPABI-preprocessed fMRI outputs

## Input structure

Prepare a `list.txt` file containing one subject ID per line. After running Step 2, each subject folder should contain:

```text
<base_dir>/
├── list.txt
├── sub001/
│   ├── gfmri.nii
│   ├── cfmri.nii
│   ├── T1.nii
│   ├── Bold.nii       # generated in Step 3
│   ├── individual_cortex.nii  # generated in Step 4
│   └── CSF_mask.nii
├── sub002/
└── ...
```

## Script order

### Step 2: Prepare files in subject folders

Run in MATLAB:

```matlab
run('step2_prepare_files.m')
```

This script copies and renames functional and structural images into each subject-specific folder:

- global functional image -> `gfmri.nii`
- CSF functional image -> `cfmri.nii`
- T1 image -> `T1.nii`

### Step 3: Generate mean BOLD reference image

Run in WSL/Linux:

```bash
bash step3_make_mean_bold.sh /path/to/base_dir /path/to/base_dir/list.txt
```

This script uses FSL to generate `Bold.nii` from `cfmri.nii`:

```bash
fslmaths cfmri.nii -Tmean Bold.nii.gz
```

### Step 4: Register cortical mask into individual functional space

Run in MATLAB:

```matlab
run('step4_register_cortex_mask.m')
```

This script coregisters `T1.nii` to `Bold.nii`, estimates normalization parameters, and generates `individual_cortex.nii` for extracting the cortical gray-matter BOLD signal.

### Step 5: Calculate primary BOLD-CSF coupling

Run in MATLAB:

```matlab
run('step5_bold_csf_coupling.m')
```

Outputs include:

- `all_average_csf_signals.xlsx`
- `all_global_bold_signals.xlsx`
- `all_ccfs.xlsx`
- subject-level signal and cross-correlation figures

The downstream BOLD-CSF coupling value should be extracted from `all_ccfs.xlsx` at the predefined lag, for example +4 s, using the sign convention described in the manuscript.

### Step 6: Derivative-based validation analysis

Run in MATLAB:

```matlab
run('step6_derivative_validation.m')
```

Outputs include:

- `all_neg_derivative_bolds.xlsx`
- `all_derivative_ccfs.xlsx`

These derivative-based outputs are intended for auxiliary methodological validation only and are not part of the primary statistical analyses.
