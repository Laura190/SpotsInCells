# SpotsInCells
Identifies cell outlines, counts number of spots in each cell, and saves counts and ROIs to OMERO.

## Requirements

- Details for connecting to an OMERO server.
- OMERO dataset ID containting image stacks with at least 2 channels.

## Setup

- Install [Fiji](https://fiji.sc/)
- Install [OMERO for ImageJ Plugin](https://www.openmicroscopy.org/omero/downloads/)
- Install [simple-omero-clients](https://github.com/GReD-Clermont/simple-omero-client)
- Install [omero_macro-extensions](https://github.com/GReD-Clermont/omero_macro-extensions)
- Install [MorphLibJ](https://imagej.net/plugins/morpholibj)

Instructions for installing the OMERO Plugins are available here: [https://omero-guides.readthedocs.io/projects/fiji/en/latest/installation.html](https://omero-guides.readthedocs.io/projects/fiji/en/latest/installation.html) \
Instructions for installing the MorphoLibJ plugins are available here: [https://imagej.net/plugins/morpholibj](https://imagej.net/plugins/morpholibj)

## Output
Saves ROIs for nuclei and spots to OMERO images and saves NumberSpotsInCells.csv to each image. The .csv files contains two columns: 1) the cell ID which relates to the ROI and 2) the number of spots in that cell.

## References

Legland, D., Arganda-Carreras, I., & Andrey, P. (2016). MorphoLibJ: integrated library and plugins for mathematical morphology with ImageJ. Bioinformatics, 32(22), 3532–3534. doi:10.1093/bioinformatics/btw413 \
Pouchin P, Zoghlami R, Valarcher R et al. Easing batch image processing from OMERO: a new toolbox for ImageJ [version 2; peer review: 2 approved]. F1000Research 2022, 11:392 (https://doi.org/10.12688/f1000research.110385.2) 
