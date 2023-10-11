Gene Trees Approach
================

**Author**: [Léo-Paul Dagallier](https://github.com/LPDagallier)  
**Last update**: 2023-10-11

------------------------------------------------------------------------

The gene trees are first inferred in a maximum likelihood (ML)
framework. Here we’ll present tree inferences with
[RAxML](https://cme.h-its.org/exelixis/web/software/raxml/) and
[IQ-TREE](http://www.iqtree.org/). You’ll find plenty of information and
details on the algorithms used and parameters in their documentation and
publications. Other ML programs exist and include
e.g. [PAML](http://abacus.gene.ucl.ac.uk/software/paml.html),
[PhyML](http://www.atgc-montpellier.fr/phyml/), or
[FastTree](http://www.microbesonline.org/fasttree/).

The inferred gene tress are then summarized in a species tree using a
pseudo-coalescent framework, as implemented in ASTRAL. Several recent
improvements and variations of the ASTRAL-III program have been
published and are now embedded in the package
[ASTER](https://github.com/chaoszhang/ASTER). We will present here 3
different variations:

- [ASTRAL](https://github.com/chaoszhang/ASTER/blob/master/tutorial/astral.md):
  similar to ASTRAL-III, requires to define a threshold to collapse
  poorly supported branches in the gene trees
- [Weigthed
  ASTRAL](https://github.com/chaoszhang/ASTER/blob/master/tutorial/astral-hybrid.md):
  similar to ASTRAL, but weights the species tree inference with the
  branch support inferred in the gene trees, supposedly providing better
  accuracy ([Zhang & Mirarab,
  2022](https://doi.org/10.1093/molbev/msac215))
- [ASTRAL-Pro2](https://github.com/chaoszhang/ASTER/blob/master/tutorial/astral-pro.md):
  similar to ASTRAL but allows for multi-copy genes (i.e. putative
  paralogs)

# Gene trees inference

For the examples here, we will infer gene trees based on the exons
sequences, aligned with MAFFT and cleaned with TrimAl. You can easily
change the code in the “inputs” chunks to use supercontigs or multi-copy
exons (paralogs) instead.

## Infer gene trees with RAxML

### Define the paths and variables

- for the inputs:

``` bash
analysis_ID="my_analysis_ID"
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_exons_align_w_refs/w_refs/trimal";
```

- for the outputs:

``` bash
step_ID="hybpiper2_exons_trimal_genetrees_raxml"
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/$analysis_ID"_"$step_ID"/";
```

- temporary directory for local users:

``` bash
path_to_tmp=$path_to_dir_out
```

- temporary directory for cluster users: depends on the cluster manager
  and its setup (please see with your cluster documentation), e.g. for
  SLURM on HiperGator:

``` bash
path_to_tmp=$SLURM_TMPDIR
```

### Copy all the files in the working directory

Go to working directory.

``` bash
cd $path_to_tmp
```

Copy the fasta files.

``` bash
scp $path_to_dir_in/*.FNA $path_to_tmp
rename -v '.FNA' '.fna' *
```

### Run RAxML

RAxML can be run on one locus after another…

``` bash
for file in $(ls -1 *.fna)
do
  raxmlHPC-PTHREADS-SSE3 -f a -x 12345 -p 12345 -# 100 -T 2 -m GTRGAMMA -O -s $file -n $file
done
```

… or in parallel (here on 4 different cores):

``` bash
ls -1 *.fna | \
parallel -j 4 "echo Starting RAXML for alignment {}; raxmlHPC-PTHREADS-SSE3 -f a -x 12345 -p 12345 -# 100 -T 2 -m GTRGAMMA -O -s {} -n {}"
```

In the above command:

- `-f a` tells RAxML to conduct a rapid Bootstrap analysis and search
  for the best-scoring ML tree in one single program run
- `-x 12345` turns on rapid bootstrapping and set 12345 as seed number
- `-p 12345` specifies a random number seed for the parsimony inferences
- `-# 100` tells RAxML to conduct 100 bootstrap
- `-T 2` tells RAxML to use 2 threads
- `-m GTRGAMMA` use the following model of substitution: GTR +
  Optimization of substitution rates + GAMMA model of rate heterogeneity
- `-O` disables check for completely undetermined sequence in alignment
- `-s` specifies the name of the alignment data file
- `-n` specifies the name of the output file

Note that the `raxmlHPC-PTHREADS-SSE3` command only works on some HPC
systems, check with your own system and installation what command should
be used to run RAxML.

### Collect gene trees

Create a subdirectory and move the inferred trees in it.

``` bash
mkdir trees
find . -name '*bipartitions.*' -exec mv -t trees {} +
```

### Collect infos on the gene trees (optional)

Create a subdirectory and move the info files in it.

``` bash
mkdir trees_info
find . -name '*info.*' -exec mv -t trees_info {} +
```

## Infer gene trees with IQ-TREE

### Define the paths and variables

- for the inputs:

``` bash
analysis_ID="my_analysis_ID"
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_exons_align_w_refs/w_refs/trimal";
```

- for the outputs:

``` bash
step_ID="hybpiper2_exons_trimal_genetrees_iqtree"
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/$analysis_ID"_"$step_ID"/";
```

- temporary directory for local users:

``` bash
path_to_tmp=$path_to_dir_out
```

- temporary directory for cluster users: depends on the cluster manager
  and its setup (please see with your cluster documentation), e.g. for
  SLURM on HiperGator:

``` bash
path_to_tmp=$SLURM_TMPDIR
```

### Copy all the files in the working directory

Go to working directory.

``` bash
cd $path_to_tmp
```

Copy the fasta files into a directory called alignments.

``` bash
mkdir alignments
scp $path_to_dir_in/*.FNA $path_to_tmp/alignments
cd $path_to_tmp/alignments
rename -v '.FNA' '.fna' *
```

### Run IQ-TREE

IQ-TREE can be run on one locus after another…

``` bash
for file in $(ls -1 alignments/*.fna )
do
  iqtree2 -s $file -m MFP+MERGE -B 1000 -bnni -alrt 1000 -T AUTO -ntmax 2 -mem 8G
done
```

… or in parallel (here on 4 different cores):

``` bash
ls -1 alignments/*.fna | \
parallel -j 4 "echo Starting IQ-TREE for alignment {}; iqtree2 -s {} -m MFP+MERGE -B 1000 -bnni -alrt 1000 -T AUTO -ntmax 2 -mem 8G"
```

In the command above:

- `-s` specifies the name of the alignment file
- `-m MFP+MERGE` specifies to carry on a model selection step with
  ModelFinderPlus (across all available models)
- `-B 1000` specifies to assess branch support with ultrafast bootstrap
- `-bnni` tells to optimize each bootstrap using a hill-climbing nearest
  neighbor interchange search
- `-alrt 1000` specifies to assess branch support with SH-like
  approximate likelihood ratio test and 1000 replicates
- `-T AUTO` specifies to select automatically the number of threads to
  use
- `-ntmax 2` specifies the maximum number of threads to use
- `-mem 8G` specifies the maximum amount of RAM to use

### Collect gene trees

Create a subdirectory and move the inferred trees in it.

``` bash
mkdir trees
find . -name '*.fna.treefile' -exec mv -t trees {} +
rename -v '.fna.treefile' '.fna' trees/*
```

### Collect infos on the gene trees (optional)

Create a subdirectory and move the info files in it.

``` bash
mkdir trees_info
find . -name '*.fna.iqtree' -exec mv -t trees_info {} +
```

# Species tree inference

The use of subsets of loci (as generated in [Loci
filtering](Loci_filtering.md)) will generally happen just before
reconstructing the species tree from gene trees. The subsets of loci are
listed in different `.txt` files stored in
`<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/my_analysis_ID`.

## ASTRAL

#### Define the path variables for downstream file manipulation

Specify the path to the directory where the ASTRAL output will be
stored.

``` bash
path_to_data="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/my_analysis_ID"
analysis_ID="my_analysis_ID"
cd $path_to_data
```

Specify the path to the directory where the gene trees were output from
RAxML or IQ-TREE.

``` bash
path_to_jobs_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS"
```

Specify the directory we want to retrieve the gene trees from.

``` bash
folder=my_analysis_ID_hybpiper2_exons_trimal_genetrees_raxml
```

For `.txt` files generated on a Windows machine and transferred to a
Linux machine (e.g. the lists of subsets of loci), this commands formats
the `.txt` files accordingly.

``` bash
dos2unix $path_to_data/*.txt
```

#### Collect the subsets of trees

Rename tree files (.fna) to .FNA. (Side note: this step is not mandatory
*per se*, I just happened to add it to homogenize the file format
between all my scripts).

``` bash
cd $path_to_jobs_out/$folder/trees ;
rename '.fna' '.FNA' *
```

Concatenate **all** the trees in a `.trees` file.

``` bash
cat *.FNA > $folder"_ALL.trees";
```

Concatenate a subset of trees. This step uses the text files that
contain subsets of loci (generated in [Loci
filtering](Loci_filtering.md)) to retrieve the gene trees to append to
the final `.trees` file.

``` bash
echo "" > $folder"_L_N.trees"
while read locus;
do
  cat *aligned.$locus*.FNA >> $folder"_L_N.trees"
done < $path_to_data/list_L_N.txt
```

#### Collapse branches with low support bootstrap \< 10

Collapsing branches with low support in the gene trees helps ASTRAL to
infer branch support in the species tree. As a rule of thumb, a
threshold of 10 for regular bootstrap is generally used, but this can be
changed (e.g increased in the case of ultrafast bootstrap).

We will use [Newick Utils](https://github.com/tjunier/newick_utils) to
collapse branch with a support below 10, in both file with all the trees
and the file with the subset of trees.

``` bash
cd $path_to_jobs_out/$folder/trees
tree=$folder"_ALL.trees"
nw_ed $tree.trees 'i & b<=10' o > $tree"_bs10.trees";
tree=$folder"_L_N.trees"
nw_ed $tree.trees 'i & b<=10' o > $tree"_bs10.trees";
```

In case you have more subsets (you can run ASTRAL for as many subsets as
you want!), it can be cumbersome to write the command for every subset,
so let’s write a loop to run Newick Utils on all of them:

``` bash
cd $path_to_jobs_out/$folder/trees
trees=$(ls -1 *.trees | grep -v "_bs" | sed 's/\.trees//g')
for tree in $trees
do
  echo Collapsing branches for $tree...
  nw_ed $tree.trees 'i & b<=10' o > $tree"_bs10.trees";
done
```

#### Run ASTRAL

Prepare the subdirectory that will receive the ASTRAL outputs:

``` bash
path_to_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/"$analysis_ID"/Astral/"
mkdir $path_to_out
```

For all the loci:

``` bash
path_to_input=$path_to_jobs_out/$folder/trees/
input_file=$folder"_ALL_bs10.trees"
output_file="astral_"$folder"_ALL_bs10.tree"
output_log="astral_"$folder"_ALL_bs10.log"
echo "astral -t 2 -i $path_to_input$input_file -o $path_to_out$output_file 2> $path_to_out$output_log"
```

For the L_N subset of loci:

``` bash
path_to_input=$path_to_jobs_out/$folder/trees/
input_file=$folder"_L_N_bs10.trees"
output_file="astral_"$folder"_L_N_bs10.tree"
output_log="astral_"$folder"_L_N_bs10.log"
echo "astral -t 2 -i $path_to_input$input_file -o $path_to_out$output_file 2> $path_to_out$output_log"
```

Similarly as above, writing manually the command for every subset can be
cumbersome, so let’s write a loop to run ASTRAL on all the files in the
folder:

``` bash
path_to_input=$path_to_jobs_out/$folder/trees/
cd $path_to_input
ls -1 *bs10.trees | \
while read input_file;
do
  output_file="astral_"$input_file".tree"
  output_log="astral_"$input_file".log"
  echo "astral -t 2 -i $path_to_input$input_file -o $path_to_out$output_file 2> $path_to_out$output_log"
done
```

#### Root the tree(s)

ASTRAL inferes unrooted species tree, so we need to root the tree. This
can be done in different ways, we’ll here use the unix-based program
[phyx](https://github.com/FePhyFoFum/phyx). As an alternative you can
also root the trees in R (e.g. function `root()` in the package `ape`).

Go to the directory where ASTRAL trees are stored and define a variable
`TREES` containing all the ASTRAL tree files in the directory.

``` bash
cd $path_to_out
TREES=astral*.tree
```

Root all the trees in a loop using `pxrr`.

``` bash
for t in $TREES
do
echo $t
pxrr -t $t -g outgroup_sample1,outgroup_sample2 > rooted.$t
done
```

- `-t` defines the tree file name
- `-g` defines the name(s) of the sample(s) to be set as outgroup(s); it
  can be a list of samples

#### Visualize the trees and export figures

Once trees are rooted, you may want to download them locally (in case
you were running ASTRAL, phyx, etc. on a cluster). You can visualize the
trees with [any visualization
software](https://en.wikipedia.org/wiki/List_of_phylogenetic_tree_visualization_software),
such as [FigTree](http://tree.bio.ed.ac.uk/software/figtree/) or
[Dendroscope](https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/dendroscope/).

In R, you can use your own function, or use the `plot_astral()` function
that is available here in the
[`plot_astral_tree.R`](PHYLOGENY_RECONSTRUCTION/R/plot_astral_tree.R)
script. This function is a wrapper of different functions including the
`geom_tree()` function (package `ggtree`), and allows to plot different
branch support, different branch length configurations, and to rename
the tips in your tree. The plots are directly saved into a .pdf file.

First set your R working directory to the path where you have your
ASTRAL trees.

``` r
setwd(dir = "<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/my_analysis_ID")
```

Load relevant packages.

``` r
library(treeio)
library(ggplot2)
library(ggtree)
library(ggimage)
library(tidyr)
```

Create a list of the files of the trees you want to plot.

``` r
trees_list <- list.files(pattern = "rooted.*.tree$")
```

If you want to rename the tip labels in your tree, you must prepare a
table with old names in one columna and the corresponding new names in
another column (see e.g. the
[`tips_rename.txt`](PHYLOGENY_RECONSTRUCTION/DATA/example_analysis_01/tips_rename.txt)
text file).

``` r
tiplabels <- read.table(file = "<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/my_analysis_ID/tips_rename.txt", col.names = c("OLD", "NEW"))
```

Define the path to the script and source the script. This will load the
`plot_astral()` function into your R environment.

``` r
path_to_plot_astral_script <- "<base_directory>DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/plot_astral_tree.R"
source(path_to_plot_astral_script)
```

Loop over all the tree file names in the `trees_list` vector defined
earlier.

``` r
for (tree_file in trees_list){
  print(tree_file)
  plot_astral(tree_file, rename = T, tiplabels = tiplabels, annotations = "LPP")
}
```

`plot_astral()` has several options, see details in the
[`plot_astral_tree.R`](PHYLOGENY_RECONSTRUCTION/R/plot_astral_tree.R)
script.

**Important note:** the trees are expected to be annotated with the
`-t 2` option in ASTRAL. Specifically, it is expected to have node
support named ‘pp1’ (for local posterior probabilities, LPP) and
‘q1’,‘q2’ and ‘q3’ (for quartet scores, QS).

## ASTRAL-weighted

🚧🚧🚧

## ASTRAL-Pro2

🚧🚧🚧
