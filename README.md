# Characteristic Distance-Based Motion Barcodes

MATLAB-based research on **characteristic distance-based motion barcode frameworks** for analyzing vibratory object motion in near-infrared (NIR) video frame sequences.

This repository accompanies the PhD thesis:

**Divagar Vakeesan**
*Characteristic Distance-Based Barcodes Extracted from Vibratory Object Motion in NIR Video Frame Sequences*
Department of Electrical and Computer Engineering
University of Manitoba
Winnipeg, Manitoba, Canada
2026

## Overview

This research presents a unified signal-processing-based framework for analyzing vibratory object motion extracted from near-infrared (NIR) video frame sequences.

A **characteristic distance-based motion barcode** representation is introduced to encode motion dynamics into compact binary temporal signatures. The research focuses on interpretable and measurement-driven characterization of intrinsic motion properties, including **periodicity, oscillation, temporal stability, and biomechanical phase transitions**.

The methodology consists of four complementary motion-analysis frameworks:

1. **Framework 01 — Temporally Lagged Vector Fields**
2. **Framework 02 — Centroid and Segmentation-Based Motion Waveforms**
3. **Framework 03 — Geometric Shape-Based Motion Waveforms**
4. **Framework 04 — Intensity-Based Motion Waveforms**

Together, these frameworks capture complementary aspects of motion, including **local flow dynamics, global displacement, structural deformation, and intensity-based variation**.

## Research Frameworks

### Framework 01 — Temporally Lagged Vector Fields

Temporally lagged optical-flow vector fields are used to characterize changes in motion dynamics across different temporal scales. Characteristic distances derived from vector-field properties are encoded into binary temporal motion barcodes.

### Framework 02 — Centroid and Segmentation-Based Motion Waveforms

Object segmentation and centroid-based measurements are used to construct temporal motion waveforms representing global object displacement and motion behavior.

### Framework 03 — Geometric Shape-Based Motion Waveforms

Geometric characteristics of the segmented moving object are transformed into temporal signals to characterize structural deformation and shape-related variations during motion.

### Framework 04 — Intensity-Based Motion Waveforms

Temporal variations in image intensity are used to construct motion waveforms representing intensity-based changes associated with object motion.

## Code Availability

This repository currently provides **representative MATLAB code for the four proposed motion-analysis frameworks**.

Several publications associated with this PhD research are currently **under review**. Therefore, the complete research implementation is not publicly available at this time.

The **main processing loop and selected implementation details have been intentionally removed from each MATLAB framework code**. The files are provided to illustrate the computational methodology and overall structure of the proposed frameworks.

Because the main processing loops have been omitted, the currently available MATLAB files **are not intended to execute as complete standalone programs or reproduce the complete experimental results reported in the thesis**.

The **full executable MATLAB implementations are intended to be released following publication of the associated research articles**.

## Repository Contents

The repository currently contains:

* **Framework 01 MATLAB code** — Temporally Lagged Vector Fields
* **Framework 02 MATLAB code** — Centroid and Segmentation-Based Motion Waveforms
* **Framework 03 MATLAB code** — Geometric Shape-Based Motion Waveforms
* **Framework 04 MATLAB code** — Intensity-Based Motion Waveforms
* **Running NIR input video**
* **Jogging NIR input video**
* **Walking NIR input video**

The MATLAB framework files are stored directly in the main repository. The three reference videos are organized in the `Input_Videos` directory.

## Repository Structure

```text
Characteristic-Distance-Motion-Barcodes/
│
├── README.md
│
├── framework01_sample.m
├── framework02_sample.m
├── framework03_sample.m
├── framework04_sample.m
│
└── Input_Videos/
    ├── running_input.mp4
    ├── jogging_input.mp4
    └── walking_input.mp4
```

## Reference Input Videos

Three representative NIR video sequences are provided as reference inputs:

* **Running**
* **Jogging**
* **Walking**

These videos correspond to the three human locomotion conditions investigated in the PhD research.

The videos are provided as **reference input data** to illustrate the type of NIR video sequences analyzed using the proposed frameworks.

## Signal Processing and Motion Barcode Generation

The complete research implementation incorporates computational and signal-processing methods including:

* Optical-flow and motion analysis
* Motion segmentation
* Temporal waveform extraction
* Hilbert transform
* Instantaneous frequency analysis
* Fourier transform
* Characteristic-distance analysis
* Threshold-based binary encoding
* Temporal motion barcode generation

The currently released MATLAB files contain representative portions of these computational procedures.

## Experimental Evaluation

The complete methodology was experimentally evaluated using NIR video sequences of human locomotion involving:

* **Running**
* **Jogging**
* **Walking**

The generated characteristic distance-based motion barcodes were evaluated against biomechanical ground-truth annotations to investigate their ability to characterize temporal motion structure, periodicity, stability, and biomechanical phase transitions.

## MATLAB Requirements

The complete research implementation was developed using **MATLAB**.

Depending on the framework, functionality from the following MATLAB toolboxes may be required:

* **Computer Vision Toolbox**
* **Image Processing Toolbox**
* **Signal Processing Toolbox**

The currently released MATLAB files are incomplete by design and are provided primarily for methodological and research reference.

## Important Note

The materials currently available in this repository are intended to support **research transparency and methodological reference** while protecting implementation details associated with manuscripts currently under peer review.

Accordingly:

* Four representative MATLAB framework files are provided.
* The **main processing loop has been intentionally removed from each framework code**.
* Selected research-specific implementation details may also be omitted.
* The MATLAB files are **not complete standalone implementations**.
* Three reference NIR input videos are provided: **running, jogging, and walking**.
* The current sample code should not be expected to reproduce the complete thesis results.
* The full executable implementations are intended to be released following publication of the associated research articles.

For complete mathematical formulations, algorithms, experimental procedures, and evaluation results, please refer to the associated PhD thesis.

## Citation

If you reference this repository or the associated methodology in academic work, please cite:

**Vakeesan, D.**
*Characteristic Distance-Based Barcodes Extracted from Vibratory Object Motion in NIR Video Frame Sequences.*
PhD Thesis, Department of Electrical and Computer Engineering, University of Manitoba, Winnipeg, Manitoba, Canada, 2026.

## Author

**Divagar Vakeesan, PhD**
Department of Electrical and Computer Engineering
University of Manitoba
Winnipeg, Manitoba, Canada

## License

No open-source license is currently provided for this repository.

Unless otherwise stated, the source code and associated research materials are provided for **academic and research reference purposes**. All rights are reserved by the author.

Please contact the author before reproducing, redistributing, modifying, or incorporating substantial portions of the code into other software or research projects.

## Disclaimer

The publicly available MATLAB files are **representative samples only** and do not constitute the complete research implementation.

The main processing loops and selected implementation details have been intentionally omitted because associated research publications remain under review.

Consequently, the sample code should **not be expected to execute as a complete pipeline or reproduce the results, figures, or quantitative findings reported in the PhD thesis**.
