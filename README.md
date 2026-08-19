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

A novel **characteristic distance-based motion barcode** representation is introduced to encode motion dynamics into compact binary temporal signatures. The research focuses on interpretable and measurement-driven characterization of intrinsic motion properties, including **periodicity, oscillation, temporal stability, and biomechanical phase transitions**.

The proposed methodology consists of four complementary motion-analysis frameworks:

1. **Framework 01 — Temporally Lagged Vector Fields**
2. **Framework 02 — Centroid and Segmentation-Based Motion Waveforms**
3. **Framework 03 — Geometric Shape-Based Motion Waveforms**
4. **Framework 04 — Intensity-Based Motion Waveforms**

Together, these frameworks capture complementary aspects of vibratory motion, including **local flow dynamics, global displacement, structural deformation, and intensity-based variation**.

## Research Frameworks

### Framework 01 — Temporally Lagged Vector Fields

Temporally lagged optical-flow vector fields are used to characterize changes in motion dynamics across different temporal scales. Characteristic distances derived from vector-field properties are encoded into binary temporal motion barcodes.

### Framework 02 — Centroid and Segmentation-Based Motion Waveforms

Object segmentation and centroid-based measurements are used to construct temporal motion waveforms representing global object displacement and motion behavior.

### Framework 03 — Geometric Shape-Based Motion Waveforms

Geometric characteristics of the segmented moving object are transformed into temporal signals to characterize structural deformation and shape-related changes during motion.

### Framework 04 — Intensity-Based Motion Waveforms

Temporal variations in image intensity are used to construct motion waveforms representing intensity-based changes associated with object motion.

## Signal Processing and Motion Barcode Generation

Depending on the framework, extracted motion information is transformed into temporal signals and analyzed using methods including:

* Hilbert transform
* Instantaneous frequency analysis
* Fourier transform
* Characteristic-distance analysis
* Threshold-based binary encoding
* Temporal motion barcode generation

The resulting binary signatures provide compact and interpretable representations of temporal motion dynamics.

## Code Availability

This repository currently contains **representative MATLAB code excerpts and sample implementations** illustrating the computational concepts developed in this research.

Several publications associated with this PhD research are currently **under review**. Therefore, the complete research implementation is not publicly released at this time.

The currently available MATLAB code is provided primarily to illustrate the methodology and computational structure. Because portions of the complete implementation have intentionally been omitted, the publicly available code **may not execute independently or reproduce the complete experimental results reported in the thesis**.

The **full executable MATLAB implementation is intended to be made publicly available following publication of the associated research articles**.

Additional source code and documentation will be added as the associated research becomes publicly available.

## Reference Input Videos

Three representative NIR video sequences are included as reference inputs:

* **Running motion**
* **Jogging motion**
* **Walking motion**

These three locomotion conditions correspond to the experimental motion sequences investigated in the PhD research.

The input videos are provided as reference material for understanding the motion sequences analyzed by the four proposed frameworks.

## Reference Output Videos

For each of the **four frameworks**, corresponding processed output videos are provided for all three motion types:

| Framework                              | Running      | Jogging      | Walking      |
| -------------------------------------- | ------------ | ------------ | ------------ |
| Framework 01 — Vector Field            | Output Video | Output Video | Output Video |
| Framework 02 — Centroid & Segmentation | Output Video | Output Video | Output Video |
| Framework 03 — Geometric Shape         | Output Video | Output Video | Output Video |
| Framework 04 — Intensity               | Output Video | Output Video | Output Video |

Therefore, the repository contains **3 reference input videos and 12 framework-specific reference output videos**.

The output videos were generated using the **complete research implementation** and are included to demonstrate the expected processing workflow and framework-specific visualization.

The reference output videos should **not be interpreted as being reproducible from the currently published sample code alone**, because portions of the complete implementation are temporarily withheld while associated publications remain under review.

## Repository Structure

```text
Characteristic-Distance-Motion-Barcodes/
│
├── README.md
│
├── Input_Videos/
│   ├── running_input.mp4
│   ├── jogging_input.mp4
│   └── walking_input.mp4
│
├── Framework_01_Vector_Field/
│   ├── framework01_sample.m
│   └── Output_Videos/
│       ├── running_output.mp4
│       ├── jogging_output.mp4
│       └── walking_output.mp4
│
├── Framework_02_Centroid_Segmentation/
│   ├── framework02_sample.m
│   └── Output_Videos/
│       ├── running_output.mp4
│       ├── jogging_output.mp4
│       └── walking_output.mp4
│
├── Framework_03_Geometric_Shape/
│   ├── framework03_sample.m
│   └── Output_Videos/
│       ├── running_output.mp4
│       ├── jogging_output.mp4
│       └── walking_output.mp4
│
└── Framework_04_Intensity/
    ├── framework04_sample.m
    └── Output_Videos/
        ├── running_output.mp4
        ├── jogging_output.mp4
        └── walking_output.mp4
```

This organization stores each input video only once while keeping the processed outputs organized according to the corresponding research framework.

## Input-to-Output Workflow

The reference materials illustrate the following overall research workflow:

**NIR Input Video → Motion Representation → Characteristic Extraction → Signal Analysis → Motion Barcode Generation → Framework-Specific Output**

For each input motion sequence—**running, jogging, and walking**—the four frameworks provide complementary representations of the underlying motion dynamics.

## Experimental Evaluation

The complete research methodology was experimentally evaluated using NIR video sequences of human locomotion involving **running, jogging, and walking**.

The generated motion barcodes were evaluated against biomechanical ground-truth annotations to investigate their ability to characterize intrinsic temporal structure, periodicity, stability, and biomechanical phase transitions.

## MATLAB Requirements

The complete research implementation was developed using MATLAB and uses functionality associated with computer vision, image processing, optical flow, signal processing, and numerical analysis.

Depending on the framework, MATLAB toolboxes may include:

* **Computer Vision Toolbox**
* **Image Processing Toolbox**
* **Signal Processing Toolbox**

The exact requirements of the complete implementation may differ from those of the currently available sample code.

## Important Note

The materials currently available in this repository are intended to provide **research transparency and methodological reference** while protecting implementation details associated with manuscripts that remain under peer review.

Accordingly:

* The MATLAB files currently provided are **representative rather than complete implementations**.
* Some research-specific processing steps and implementation details are intentionally omitted.
* The sample code may not execute as a complete standalone pipeline.
* Three reference NIR input videos are provided: **running, jogging, and walking**.
* Corresponding output videos generated by the complete implementation are provided for **each of the four frameworks**.
* The output videos demonstrate the expected behavior and visualization of the complete research implementation.
* The complete executable MATLAB implementation is intended for release following publication of the associated research articles.

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

The publicly available MATLAB code represents only a portion of the complete research implementation and is provided for methodological reference.

The complete implementation contains additional processing, parameterization, characteristic extraction, analysis, visualization, and evaluation components that are not currently released because associated research publications remain under review.

Consequently, the sample code should **not be expected to reproduce all results, figures, output videos, or quantitative findings reported in the PhD thesis**.
