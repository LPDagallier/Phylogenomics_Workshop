
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
**Last update**: 2023-10-09

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

At the end of the HybPiper steps (including the paralogy extraction
step, see below), you should usually end up with sequences extracted for
the successful loci in the following directories:

- `retrieved_exons`: extracted exons
- `retrieved_supercontigs`: extracted exons + (partial) introns
- `retrieved_aa`: extracted exons translated as amino acids
- `paralogs_all` and `paralogs_no_chimeras`: extracted multi-copies
  exons

### Paralogs assessement and resolution

HybPiper also allow to asses paralogy and to extract putative paralogous
sequences. Then you can either assess the putative paralogs one by one
and decide if these should be discarded, or use
[ParaGone](https://github.com/chrisjackson-pellicle/ParaGone) to run a
**phylogenetic aware** paralogy resolution step.

See [**Paralogs**](Paralogs.md) for more details.

##### Paralogy assessement with HybPiper

:point_right: See the associated :computer: [scripts for local
use](PHYLOGENY_RECONSTRUCTION/SCRIPTS_local/hybpiper2_paralogs.sh) and
:woman_technologist: [scripts for cluster (SLURM)
use](PHYLOGENY_RECONSTRUCTION/SCRIPTS_cluster/hybpiper2_paralogs_TEMPLATE.sh).

##### Paralogy resolution with ParaGone

:construction: :construction: :construction:  
:point_right: (TO DO) See the associated :computer: [scripts for local
use]() and :woman_technologist: [scripts for cluster (SLURM) use]().
:construction: :construction: :construction:

### Loci filtering

Loci can be filtered. As we have seen [earlier](Paralogs.md), they can
be filtered on their putative paralogy status (i.e. completely remove
putative paralogous loci).

Loci can also be filtered on their **assembly statistics**. Specifically
they can be filtered on a percentage of samples (N) for which a
percentage of the length of the loci has been assembled (L). For
simplicity, let’s call these the **L_N subsets**. For example, a 75_75
subset will only include those loci that have been recovered for at
least 75% of their length in 75% of the samples.

Additional lists of loci can be drawn from the paralogy statistics.
These are exploratory and should be used with caution. They include
e.g. list of loci with maximum 1 copy (no paralogy at all), or loci with
a median of 2 copies per sample.

See [loci filtering](Loci_filtering.md) for full details.

As a general rule, I advise to actually filter the loci after the gene
trees reconstruction step.

### Alignment

\[:construction: UNDER CONSTRUCTION… :construction:\]

After extracting the sequences (exons, supercontigs or multicopies
exons), we need to align them.

Here we’ll use
[MAFFT](https://mafft.cbrc.jp/alignment/software/algorithms/algorithms.html)
to align, but other program do exist
(e.g. [MUSCLE](https://drive5.com/muscle5/manual/commands.html),
[Clustal](http://www.clustal.org/),
[MACSE](https://www.agap-ge2pop.org/macse/?menu=releases)).

Sequences can be aligned “naively” or informed by the locus reference
sequence. As a rule of thumb, I would advise to align with the locus
reference sequence, because it is conceptually less prone to alignment
errors.

See [Alignment](Alignment.md) for details on the alignment steps.

### Phylogenetic reconstruction

\[:construction: UNDER CONSTRUCTION… :construction:\]

#### Gene trees approach

#### Concatenation approach

## Genome skimming

\[:construction: UNDER CONSTRUCTION… :construction:\]  
\[to be completed…\]

------------------------------------------------------------------------
