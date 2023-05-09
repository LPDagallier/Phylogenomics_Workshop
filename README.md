
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Phylogenomics Workshop

<!-- badges: start -->

![Workshop
Material](https://img.shields.io/badge/Workshop-Material-brightgreen)
[![License: GPL (\>=
2)](https://img.shields.io/badge/License-GPL%20%28%3E%3D%202%29-blue.svg)](https://choosealicense.com/licenses/gpl-2.0/)
![Badge last
commit](https://img.shields.io/github/last-commit/LPDagallier/Phylogenomics_Workshop?style=flat-square)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

Resource material for the plant phylogenomics workshop.

**TO ADD** – The presentation can be found [here](./prez.pdf)

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
in the [presentation.pdf **TO ADD**]() file.

Advanced workflow details, with associated commands and scripts, are
provided on separate pages. Please read the [note for the advanced
workflow](Note_for_advanced_wf.md) beforehand. For SLURM users,
additional .sh scripts are provided as well (to be run with `sbatch`).

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

The reads obtained from the sequencing have to be cleaned before they
can be used for downstream analysis.  
:point_right: See the [Reads Cleaning](reads_cleaning.md) document for a
detailed explanation.

### HybPiper 2

HybPiper uses clean reads to create per samples assemblies and to
extract the targeted sequences.

Below is presented the basic use of HybPiper, based on their [original
tutorial](https://github.com/mossmatters/HybPiper/wiki/Tutorial).

:point_right: **See [HybPiper2](HybPiper2.Rmd) for more advanced
HybPiper workflow details**.  
(in HybPiper2: explain all the steps in Rmarkdown + provide a .sh script
for general + script for SLURM users)

Basically, HybPiper needs 3 inputs:  
- clean reads for each sample (R1 and R2 .fastq)  
- a file that contains the sequence(s) of the targeted loci
(`targetfile.fasta`)  
- list of the samples to assemble (`namelist.txt`)

#### Assembly

Assemble reads for Sample1:

``` bash
hybpiper assemble –t_dna targetfile.fasta –r Sample1*.fastq --run_intronerate
```

Loop over all the samples:

``` bash
while read name;
do
    hybpiper assemble -t_dna targetfile.fasta -r $name*.fastq --prefix $name --run_intronerate ; 
done < namelist.txt
```

##### Summary statistics and plot

To output the statistics tables (`genes_sequences_lengths.tsv` and
`hybpiper_genes_statistics.tsv`):

``` bash
hybpiper stats -t_dna targetfile.fasta --seq_lengths_filename genes_sequences_lengths --stats_filename hybpiper_genes_statistics gene namelist.txt
```

To plot the recovery heatmap:

``` bash
hybpiper recovery_heatmap --heatmap_dpi 300 --heatmap_filetype pdf --heatmap_filename recovery_heatmap_exons genes_sequences_lengths.tsv
```

#### Loci extraction

To extract the assembled sequences for every locus:

``` bash
mkdir retrieved_exons
hybpiper retrieve_sequences dna -t_dna targetfile.fasta --sample_names namelist.txt --fasta_dir retrieved_exons
```

#### Paralogs identification

To identify the paralogs, HybPiper will extract all the copies assembled
for each genes when multiple copies per gene per sample where assembled.

``` bash
hybpiper paralog_retriever namelist.txt -t_dna targetfile.fasta --heatmap_filetype pdf --heatmap_dpi 300
```

Run a quick phylogenetic reconstruction of the loci to inspect for the
multi-copies loci:

``` bash
cd paralogs_all
cat locus1_paralogs_all.fasta | mafft --auto | FastTree -nt -gtr > locus1_paralogs_all.tre
```

Run the R script [**INSERT LINK TO SCRIPT**
`plot_hybpiper_paralog_trees.R`]() to visualize the trees in a
convenient way.

``` bash
Rscript plot_hybpiper_paralog_trees.R
```

### Alignment

See [Alignment](Alignment.Rmd) for details.

### Phylogenetic reconstruction

#### Gene trees approach

#### Concatenation approach

## Genome skimming

\[to be completed…\]

------------------------------------------------------------------------

------------------------------------------------------------------------

------------------------------------------------------------------------

# Sequence recovery

## Reads cleaning

## Assembly and loci extraction

### Targeted sequencing

#### HybPiper2

#### Captus

### Genome skimming

# Phylogenetic reconstruction

# Targeted sequencing

## Reads cleaning

## Sequence recovery

### HybPiper 2

### Captus

\[to be completed\]

## Phylogenetic reconstruction

### Alignment

### Alignment trimming

### Tree estimation

#### Gene trees approach

#### Concatenation approach

# Genome skimming

\[to be completed…\]
