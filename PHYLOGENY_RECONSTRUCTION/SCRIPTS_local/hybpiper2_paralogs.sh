#!/bin/bash
##########################################################################
############                                       ########################
############      HYBPIPER PARALOGS RETRIEVER      ########################
############                                       ########################
##########################################################################

###################################################
#### 1. Preparation 
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed
# The analysis ID and step ID will be used as a preffix or suffix in scripts, file names and/or folder names
# must be unique to THIS run of analysis (that is this combination of samples, reference file, HYbPiper parameters, etc.)
analysis_ID="example_analysis_01"

# DATA-RELATED FILES:
# Change the path_to_dir_in to the directory where you extracted the sequences for exons and introns (step before)
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/<example_analysis_01>_hybpiper2_extract_<JOB_ID>";

# Change the path_to_assemblies to the directory where you stored the assemblies:
path_to_assemblies="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/<assemblies_storage_folder>"

# Note that depending on your directory organization, path_to_dir_in and path_to_assemblies may be the same folder

path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA";
path_to_tmp=$path_to_dir_in

# REFERENCE FILE:
path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FAA"

# CUSTOM SCRIPTS FILES
path_to_plot_paralogs_R_script="<base_directory>l/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/R"

####################################################
##### 1 Assess putative paralog loci
####################################################
cd $path_to_assemblies

echo "Starting retrieving putative paralog loci"
hybpiper paralog_retriever $path_to_dir_in/namelist.txt -t_dna $path_to_ref/$reference_fasta_file --heatmap_filetype pdf --heatmap_dpi 300 --fasta_dir_all $path_to_dir_in/paralogs_all --fasta_dir_no_chimeras $path_to_dir_in/paralogs_no_chimeras --paralog_report_filename $path_to_dir_in/paralog_report --paralogs_above_threshold_report_filename $path_to_dir_in/paralogs_above_threshold_report --heatmap_filename $path_to_dir_in/paralog_heatmap
echo "Done retrieving putative paralog loci"

####################################################
##### 2 Filter putative paralog loci
####################################################
cd $path_to_dir_in
cat paralogs_above_threshold_report.txt | sed '1,/The gene names are:/d' > paralogs_all/loci_with_paralog_warning.txt

####################################################
##### 3 Fast alignment and phylo reconstruction
####################################################
cd $path_to_dir_in
echo "Starting alignment and fast phylo reconstruction for all the putative paralog loci"
cd paralogs_all

# run the alignment + fast tree inference in parallel: change the j parameter to the number of threads you want to use
for locus in $(cat loci_with_paralog_warning.txt) ;
do
echo "cat "$locus"_paralogs_all.fasta | mafft --auto --quiet - | FastTree -nt -gtr > "$locus"_paralogs_all.tre"
done | parallel -j4

echo "Done alignment and fast phylo reconstruction for all the putative paralog loci"

mkdir paralog_trees
mv *.tre paralog_trees
cd paralog_trees

####################################################
##### 5 Plot phylo trees
####################################################

scp $path_to_plot_paralogs_R_script/"plot_hybpiper_paralog_trees.R" .
Rscript plot_hybpiper_paralog_trees.R
mv paralog_trees.pdf $path_to_tmp

echo "Done assessing putative paralog loci..."
echo "FINISHED"