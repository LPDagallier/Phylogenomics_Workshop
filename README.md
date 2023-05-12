
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Phylogenomics Workshop

<!-- badges: start -->

![Workshop
Material](https://img.shields.io/badge/status-under_construction-orange)
![Workshop
Material](https://img.shields.io/badge/Workshop-Material-brightgreen)
[![License: GPL (\>=
2)](https://img.shields.io/badge/License-GPL%20%28%3E%3D%202%29-blue.svg)](https://choosealicense.com/licenses/gpl-2.0/)
![Badge last
commit](https://img.shields.io/github/last-commit/LPDagallier/Phylogenomics_Workshop)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

> Léo-Paul Dagallier - May 8<sup>th</sup> - 10<sup>th</sup> 2023

Resource material for the plant phylogenomics workshop.

The presentation can be found
[here](./Plant_Phylogenomics_Workshop_001.pdf)

To go from a set of plant specimens to a phylogenetic inference, the
main steps are ordered as follow:

- (DNA extraction –not covered here)
- Sequence recovery
  - Reads cleaning  
  - Assembly  
  - Loci extraction  
- Phylogenetic reconstruction
  - Alignment  
  - Alignment trimming  
  - Tree inferences

The details of these steps may vary depending of the type of data
analysed and the methods used. Here are presented the details for
targeted sequencing data and different methods, with the associated
commands. A simple presentation of the commands for each step is given
in the [presentation .pdf file](./Plant_Phylogenomics_Workshop_001.pdf).

Advanced workflow details, with associated commands and scripts, are
provided here on separate pages. Please read the [notes for the advanced
workflow](Notes_for_advanced_wf.md). For SLURM users (cluster),
additional .sh scripts are provided for each step (to be run with
`sbatch`).

## Targeted sequencing

Targets low-copy elements of the genome, ideally single-copy orthologous
loci.

### Target sequences and probe sets

The downstream analyses need that we use a set of target sequences.

For Melastomataceae a probe set was designed ([Jantzen et
al. 2020](https://bsapubs.onlinelibrary.wiley.com/doi/abs/10.1002/aps3.11345)),
but due to several concerns, it was cleaned and updated (Dagallier &
Michelangeli, in press.). :point_right: See the
[here](https://github.com/LPDagallier/Clean_Melasto_probe_set) for more
details.

For ‘universal’ probe sets, see e.g.:  
- Angiosperm353 ([Johnson et
al. 2019](https://doi.org/10.1093/sysbio/syy086))  
- Mega353 ([McLay et
al. 2021](https://github.com/chrisjackson-pellicle/NewTargets))

### Reads cleaning

\[UNDER CONSTRUCTION…\]  
The reads obtained from the sequencing have to be cleaned before they
can be used for downstream analysis.  
:point_right: See the [Reads Cleaning (TO DO)](reads_cleaning.md)
document for a detailed explanation.

### HybPiper 2

HybPiper uses clean reads to create per samples assemblies and to
extract the targeted sequences.

:point_right: See HybPiper’s [original
tutorial](https://github.com/mossmatters/HybPiper/wiki/Tutorial) for
basic use.

:point_right: **See [HybPiper2](HybPiper2.md) for advanced HybPiper
workflow details**.

### Paralogs assessement

\[UNDER CONSTRUCTION…\]  
See [Paralogs (TO DO)](Paralogs.md) for details.

### Loci filtering

\[UNDER CONSTRUCTION…\]  
See [loci filtering (TO DO)](Loci_filtering.md) for details.

### Alignment

\[UNDER CONSTRUCTION…\]  
See [Alignment (TO DO)](Alignment.md) for details.

### Phylogenetic reconstruction

\[UNDER CONSTRUCTION…\]

#### Gene trees approach

#### Concatenation approach

## Genome skimming

\[UNDER CONSTRUCTION…\]  
\[to be completed…\]

------------------------------------------------------------------------
