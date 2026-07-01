# BOLD-CSF Coupling Analysis Pipeline

## Overview

This repository contains the complete pipeline used to quantify coupling between cortical blood-oxygen-level-dependent (BOLD) activity and cerebrospinal fluid (CSF) signals from resting-state fMRI data.

The pipeline was developed for the study:

**Surrogates of Brain Fluid Dynamics Associated with Persistence of Post-COVID-19 Brain Fog and Cognitive Impairment**

The workflow combines DPABI preprocessing, subject-specific cortical mask generation, BOLD-CSF coupling calculation, and derivative-based validation analyses.

---

## Pipeline Overview

```text
Raw rs-fMRI + T1-weighted MRI
            │
            ▼
Step 1. DPABI preprocessing
            │
            ▼
globalFunImg + CSF_FunImg
            │
            ▼
Step 2. Data preparation
            │
            ▼
Step 3. Mean BOLD image generation
            │
            ▼
Step 4. Subject-specific cortical mask generation
            │
            ▼
Step 5. BOLD-CSF coupling calculation
            │
            ▼
Step 6. Derivative-based validation analysis
```

---

# Requirements

## Software

* MATLAB R2021a or later
* SPM12
* DPABI / DPARSF
* FSL (tested under WSL/Linux)

## Input Data

For each participant:

* Resting-state fMRI
* T1-weighted MRI
* Subject list (`list.txt`)

---

# Step 1. Resting-State fMRI Preprocessing

## Software

DPABI / DPARSF based on SPM12.

## Purpose

To preprocess resting-state fMRI data before extraction of cortical BOLD and CSF signals.

## Preprocessing Procedures

The following preprocessing steps were performed:

1. Removal of the first 10 volumes
2. Slice timing correction
3. Realignment (head motion correction)
4. Coregistration with T1-weighted image
5. Spatial normalization
6. Nuisance regression:

   * Friston 24 motion parameters
   * White matter signal
   * CSF signal
7. Spatial smoothing (FWHM = 4 mm)
8. Temporal filtering (0.01–0.08 Hz)

## Quality Control

Subjects were excluded if:

* Translation > 2 mm
* Rotation > 2°
* Mean FD > 0.2

## Outputs

Two preprocessed datasets were generated:

```text
globalFunImg/
```

Used for extraction of cortical BOLD signals.

```text
CSF_FunImg/
```

Used for extraction of CSF signals.

---

# Step 2. Data Preparation

## Script

```text
step2_prepare_data.m
```

## Purpose

To organize all required imaging files into a unified subject-wise directory structure.

## Procedure

For each participant:

* Copy global functional image
* Copy CSF functional image
* Copy T1-weighted image

Rename files as:

```text
gfmri.nii
cfmri.nii
T1.nii
```

## Output

```text
SubjectID/
├── gfmri.nii
├── cfmri.nii
└── T1.nii
```

---

# Step 3. Mean BOLD Image Generation

## Script

```bash
step3_generate_mean_bold.sh
```

## Purpose

Generate a mean functional image used for subsequent image registration.

## Command

```bash
fslmaths cfmri.nii -Tmean Bold.nii.gz
```

## Output

```text
Bold.nii
```

---

# Step 4. Subject-Specific Cortical Mask Generation

## Script

```text
step4_generate_cortex_mask.m
```

## Purpose

Generate an individual cortical gray matter mask in native functional space.

## Procedure

1. Coregister T1 image to mean BOLD image.
2. Estimate spatial normalization using SPM12.
3. Generate inverse deformation field.
4. Warp cortical atlas from template space into subject functional space.
5. Generate individual cortical mask.

## Output

```text
individual_cortex.nii
```

This mask is subsequently used to extract cortical BOLD signals.

---

# Step 5. BOLD-CSF Coupling Calculation

## Script

```text
step5_bold_csf_coupling.m
```

## Purpose

Quantify coupling between cortical BOLD activity and CSF flow signals.

## CSF Signal Extraction

CSF signals are extracted from voxels contained within the CSF mask.

For each voxel:

* Time series are extracted
* Z-score normalization is performed

The mean CSF signal is then calculated across all CSF voxels.

## Cortical BOLD Signal Extraction

Global cortical BOLD signals are extracted using the subject-specific cortical mask.

For each voxel:

* Time series are extracted
* Z-score normalization is performed

The mean cortical BOLD signal is then calculated across all cortical voxels.

## Cross-Correlation Analysis

Cross-correlation functions are calculated between:

```text
Global cortical BOLD signal
and
CSF signal
```

using:

```matlab
xcorr(global_bold_signal, average_csf_signal,'coeff')
```

Cross-correlations are evaluated across temporal lags.

Following previous BOLD-CSF coupling studies, the negative peak occurring at approximately +4 seconds is used to characterize BOLD-CSF coupling strength.

A weaker (less negative) correlation indicates reduced BOLD-CSF coupling.

## Outputs

```text
all_average_csf_signals.xlsx
all_global_bold_signals.xlsx
all_ccfs.xlsx
```

## Primary Analysis

All analyses reported in the manuscript were based on the original BOLD-CSF cross-correlation obtained in this step.

This includes:

* Group comparisons
* Correlation analyses
* Cox regression analyses
* Mediation analyses
* Prognostic modeling

---

# Step 6. Derivative-Based Validation Analysis

## Script

```text
step6_derivative_validation.m
```

## Purpose

Perform a supplementary methodological validation analysis.

## Procedure

The negative first-order derivative of the global BOLD signal is calculated:

```matlab
neg_derivative_bold = -diff(global_bold_signal);
```

Cross-correlations are then calculated between:

```text
Negative first-order derivative of BOLD signal
and
CSF signal
```

## Outputs

```text
all_neg_derivative_bolds.xlsx
all_derivative_ccfs.xlsx
```

## Important Note

The derivative-based analysis was performed solely as a validation procedure and was not used in any downstream statistical analyses reported in the manuscript.

All reported results are based exclusively on the original BOLD-CSF coupling generated in Step 5.

---

# Repository Structure

```text
BOLD-CSF-Coupling/

├── README.md

├── step2_prepare_data.m
├── step3_generate_mean_bold.sh
├── step4_generate_cortex_mask.m
├── step5_bold_csf_coupling.m
├── step6_derivative_validation.m

├── example/
│   └── list.txt

└── .gitignore
```

---

# Citation

If you use this pipeline, please cite:

Zhou S, Wang Z, Liu X, et al.

Surrogates of Brain Fluid Dynamics Associated with Persistence of Post-COVID-19 Brain Fog and Cognitive Impairment.

---

# Contact

Xiaoduo Liu

2270092394@qq.com/a2270092394@gmail.com

Department of Neurology

Xuanwu Hospital, Capital Medical University

Beijing, China
