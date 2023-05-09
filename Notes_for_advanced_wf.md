Notes for the advanced workflow
================

#### Stay tidy and organized

Bioinformatic analyses can very quickly become a mess if the files and
folders are not stored properly in an organized manner. Keeping things
tidy and organized is good habit to have for reproducible science, and
it is also a huge time saver when you will have to come back to your
analyses a couple of months (or years) later because reviewer 2 asked
you to redo some analysis changing this or this parameter.

There are many different ways to organize your workflow and files and
folders, and the best one is surely the one you are comfortable with.

For clarity, I present below the way I organized my workflow and working
directories. Feel free to adopt it, to adapt it, or to create your own.
Note that the scripts presented in this repo follow this files/folders
organization.  
Also, keep in mind that changing your files/folders organization in the
middle of a project will cause some scripts to not work anymore except
if you come back to those scripts and modify them.

My working directories are organized as follow:

``` bash
<base_directory>
 ├── DATASETS
 │   └── PHYLOGENOMICS
 │       └── target_references
 │           ├── # here are all the reference files
 │           ├── Angio353_oneline.fa
 │           └── Melastomataceae_689_clean.fa
 └── DATA_ANALYSES
     ├── READS_CLEANING
     │   ├── SCRIPTS_cluster
     │   │   ├── # here are all the .sh scripts
     │   │   ├── # related to reads cleaning, e.g.:
     │   │   └── reads_cleaning_<plate_ID>.sh
     │   ├── # here are all the outputs folders
     │   ├── # from read_cleaning.sh, e.g.:
     │   └── <plate_ID>
     │        ├── ...
     │        └── ...
     └── PHYLOGENY_RECONSTRUCTION
         ├── DATA
         │   ├── # here are 1 folder per analysis
         │   ├── # 1 analysis = 1 set of samples being analysed
         │   ├── # each folder contains data-related files
         │   ├── # and some outputs (like final figures)
         │   └── <analysis_ID>
         │        ├── ...
         │        └── ...
         ├── SCRIPTS_cluster
         │   ├── # here are all the .sh scripts
         │   ├── # related to the phylogeny reconstruction, e.g.:
         │   ├── hybiper_<analysis_ID>.sh
         │   └── genetrees_raxml_<analysis_ID>.sh
         └── JOBS_OUTPUTS
             ├── # here are all the jobs output folders
             ├── # from the scripts in SCRIPTS_cluster, e.g.:
             ├── hybiper_<analysis_ID>_<JOB_ID>
             └── genetrees_raxml_<analysis_ID>_<JOB_ID>
```

The `<base_directory>` corresponds to my local directory (on my own
computer `C:\Users\<username>\Documents\RESEARCH`) **and** to my distant
working directory on the cluster (e.g. `/blue/soltis/<username>`). This
means that this folder organisation is duplicated (or mirrored) on both
devices. With this mirror, it gets easy to stay organized with a
transfer software like
[WinSCP](https://sourceforge.net/projects/winscp/) or
[FileZilla](https://filezilla-project.org/). For example, when I modify
a `.sh` script in the *local* `SCRIPTS_cluster`, I transfer it to the
*distant* `SCRIPTS_cluster` folder.

#### Use unique analysis identifiers

In my workflow, I assign an unique identifier to **every** analysis I
run, and write new scripts specifically for *this* analysis. Even if I
run the same analysis just changing a single parameter, or adding an
extra sample, I will have a specific working directory and specific
scripts for *this and only this* analysis. This is to avoid confusion
and to be able to understand what have been done, even months after
having run the analysis.

Usually, will define the **`<analysis_ID>`** that defines the set of
samples analysed (e.g. “*Merianieae_001*”, “*Carribean_Miconia_001*”).
Each **`<analysis_ID>`** gets its own sub-directory created in the
`<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA` directory
(see above), in which files related to this analysis (e.g. list of
samples, list of identified paralogs, list of filtered loci) are stored
along with some outputs (e.g. recovery statistics, inferred phylogenetic
tree).

In the scripts, I will also define the **`<step_ID>`** that defines the
specific type of analysis and parameters used
(e.g. “*hybpiper2_assemble_no_stiched*”,
“*hybpiper2_supercontigs_align_w\_refs*”,
“*captus_align_nucl_genes_pl3*”)
