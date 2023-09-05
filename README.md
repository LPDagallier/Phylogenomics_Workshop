
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

**Author**: [Léo-Paul
Dagallier](https://orcid.org/0000-0002-3270-1544)  
**Last update**: 2023-09-05

------------------------------------------------------------------------

Resource material for the plant phylogenomics workshop led at
[NYBG](https://www.nybg.org/science-project/a-phylogenomics-approach-to-resolving-one-of-the-worlds-most-diverse-tropical-angiosperm-radiations-melastomataceae/)
(May 8<sup>th</sup> - 10<sup>th</sup> 2023).

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

#### Melastomataceae

:warning: For **Melastomataceae** a probe set was designed ([Jantzen et
al. 2020](https://bsapubs.onlinelibrary.wiley.com/doi/abs/10.1002/aps3.11345)),
but due to several concerns, it was cleaned and updated (Dagallier &
Michelangeli, in press.). :point_right: See
[here](https://github.com/LPDagallier/Clean_Melasto_probe_set) for more
details. :point_left:

From this clean and updated probe set, it is also recommended to remove
the “outlier” loci and to further [remove short
sequences]((https://github.com/mossmatters/HybPiper/wiki/Troubleshooting,-common-issues,-and-recommendations#14-fixing-and-filtering-your-target-file)).  
:sparkles: The **final clean probe set** (outlier loci and short
sequences removed) can be found in the present repo: [`.FNA`
file](PHYLOGENY_RECONSTRUCTION/PROBE_SET_CLEAN_v5.FNA) and [`.FAA`
file](PHYLOGENY_RECONSTRUCTION/PROBE_SET_CLEAN_v5_prot.FAA). :sparkles:

#### Others

For ‘universal’ probe sets, see e.g.:  
- Angiosperm353 ([Johnson et
al. 2019](https://doi.org/10.1093/sysbio/syy086))  
- Mega353 ([McLay et
al. 2021](https://github.com/chrisjackson-pellicle/NewTargets))

### Reads cleaning

The reads obtained from the sequencing have to be cleaned before they
can be used for downstream analysis.  
:point_right: See the [Reads Cleaning](Reads_cleaning.md) document for a
detailed workflow.

### HybPiper 2

HybPiper uses clean reads to create per samples assemblies and to
extract the targeted sequences.

:point_right: See HybPiper’s [original
tutorial](https://github.com/mossmatters/HybPiper/wiki/Tutorial) for
basic use.

:point_right: **See [HybPiper2](HybPiper2.md) for advanced HybPiper
workflow details**, and associated :computer: scripts for local use
([assembly](PHYLOGENY_RECONSTRUCTION/SCRIPTS_local/hybpiper2_assemble.sh)
and
[extraction](PHYLOGENY_RECONSTRUCTION/SCRIPTS_local/hybpiper2_extract.sh))
and :woman_technologist: scripts for cluster (SLURM) use
([assembly](PHYLOGENY_RECONSTRUCTION/SCRIPTS_cluster/hybpiper2_assemble_TEMPLATE.sh)
and
[extraction](PHYLOGENY_RECONSTRUCTION/SCRIPTS_cluster/hybpiper2_extract_TEMPLATE.sh)).

### Paralogs assessement

HybPiper also allow to asses paralogy and to extract putative paralogous
sequences.

See [**Paralogs**](Paralogs.md) for details.

:point_right: See also the associated :computer: [scripts for local
use](PHYLOGENY_RECONSTRUCTION/SCRIPTS_local/hybpiper2_paralogs.sh)

\[:construction: UNDER CONSTRUCTION… :construction:\] and
:woman_technologist: [scripts for cluster (SLURM)
use](PHYLOGENY_RECONSTRUCTION/SCRIPTS_cluster/).

### Loci filtering

\[:construction: UNDER CONSTRUCTION… :construction:\]  
See [loci filtering (TO DO)](Loci_filtering.md) for details.

### Alignment

\[:construction: UNDER CONSTRUCTION… :construction:\]  
See [Alignment (TO DO)](Alignment.md) for details.

### Phylogenetic reconstruction

\[:construction: UNDER CONSTRUCTION… :construction:\]

#### Gene trees approach

#### Concatenation approach

## Genome skimming

\[:construction: UNDER CONSTRUCTION… :construction:\]  
\[to be completed…\]

------------------------------------------------------------------------
