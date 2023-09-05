#!/bin/bash

############      SLURM CONFIGURATION      ###################
#SBATCH --job-name=hybpiper2_extract_no_stitched_example_analysis_01
#SBATCH --account=<INSERT ACCOUNT e.g.: soltis>
#SBATCH --qos=<INSERT QUEUE NAME e.g.: soltis>
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16gb 
#SBATCH --time=5-00:00:00
#SBATCH --mail-user=<INSERT YOUR EMAIL>
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-%x-%j.out
############################################################

echo "JOB CONFIGURATION"
echo "Job ID: " $SLURM_JOB_ID
echo "Name of the job: " $SLURM_JOB_NAME
echo "Node allocated to the job: " $SLURM_JOB_NODELIST
echo "Number of nodes allocated to the job: " $SLURM_JOB_NUM_NODES
echo "Number of CPU tasks in this job: " $SLURM_NTASKS
echo "Directory from which sbatch was invoked: " $SLURM_SUBMIT_DIR
echo "Temporary folder in which the job runs: " $SLURM_TMPDIR

###################################################
#### 1. Preparation
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed
analysis_ID="example_analysis_01"

# REFERENCE FILE:
path_to_ref="/blue/soltis/dagallierl/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="PROBE_SET_CLEAN_v5_prot.FAA"

# CUSTOM SCRIPTS FILES
path_to_plot_paralogs_R_script="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION"

# PATH TO DIR IN
# Change the path_to_dir_in to the directory where you extracted the sequences for exons and introns (step before)
path_to_dir_in="<base_directory>/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/<analysis_ID>_hybpiper2_extract";
path_to_tmp=$path_to_dir_in

# PATH TO ASSEMBLIES
# Change the path_to_assemblies to the directory where you stored the assemblies:
path_to_assemblies="<base_directory>/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/STORAGE_hybpiper2_no_stitched_assemblies"

# Note that depending on your directory organization, path_to_dir_in and path_to_assemblies may be the same folder

# load module HybPiper
module load hybpiper/2.1.6

####################################################
##### 2. Assess putative paralog loci
####################################################
cd $path_to_assemblies

echo "Starting retrieving putative paralog loci"
hybpiper paralog_retriever $path_to_dir_in/namelist.txt -t_dna $path_to_ref/$reference_fasta_file --heatmap_filetype pdf --heatmap_dpi 300 --fasta_dir_all $path_to_dir_in/paralogs_all --fasta_dir_no_chimeras $path_to_dir_in/paralogs_no_chimeras --paralog_report_filename $path_to_dir_in/paralog_report --paralogs_above_threshold_report_filename $path_to_dir_in/paralogs_above_threshold_report --heatmap_filename $path_to_dir_in/paralog_heatmap
echo "Done retrieving putative paralog loci"

####################################################
##### 3. Filter putative paralog loci
####################################################
cd $path_to_dir_in
cat paralogs_above_threshold_report.txt | sed '1,/The gene names are:/d' > paralogs_all/loci_with_paralog_warning.txt

####################################################
##### 4. Fast alignment and phylo reconstruction
####################################################
cd $path_to_dir_in
echo "Starting alignment and fast phylo reconstruction for all the putative paralog loci"
cd paralogs_all

# Load modules for alignment and fast phylo reconstruction
module load parallel
module load mafft/7.490
module load fasttree
module load seqkit/2.0.0

for locus in $(cat loci_with_paralog_warning.txt) ;
do
echo "cat "$locus"_paralogs_all.fasta | mafft --auto --quiet - | FastTree -nt -gtr > "$locus"_paralogs_all.tre"
done | parallel -j$SLURM_NTASKS

echo "Done alignment and fast phylo reconstruction for all the putative paralog loci"

mkdir paralog_trees
mv *.tre paralog_trees
cd paralog_trees

####################################################
##### 5. Plot paralogs phylo trees
####################################################

scp $path_to_plot_paralogs_R_script/"plot_hybpiper_paralog_trees.R" .
module load R/4.1
Rscript plot_hybpiper_paralog_trees.R
mv paralog_trees.pdf $path_to_tmp

echo "Done assessing putative paralog loci..."
echo "FINISHED"