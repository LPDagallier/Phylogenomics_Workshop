#!/bin/bash
#################################################################
############                             ########################
############      HYBPIPER ASSEMBLE      ########################
############                             ########################
#################################################################

###################################################
#### 1. Preparation 
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed
# The analysis ID and step ID will be used as a preffix or suffix in scripts, file names and/or folder names
# must be unique to THIS run of analysis (that is this combination of samples, reference file, HYbPiper parameters, etc.)
analysis_ID="example_analysis_01"

# DATA-RELATED FILES:
# Prepare (locally) the following files:
#namelist.txt: contains the sample names that will be analysed
#input_fastq: contains the copying comands for batch-copy the fastq files
#files_renaming.txt: contains the renaming comands for batch-rename the fastq files
#These files have to be in a folder that has the same name as analysis_ID situated in path_to_dir_in:
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA";

# REFERENCE FILE:
path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FAA"

# OUTPUTS:
# change step_ID depending on the hybpiper parameters of this specific run
step_ID="hybpiper2_assemblies_no_stiched"
# OUTPUT FOLDER
# where the ouptputs will be stored
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_"$step_ID"/";

# DEFINE TEMPORARY DIRECTORY:
path_to_tmp=$path_to_dir_out # if working locally
mkdir $path_to_tmp
# path_to_tmp=$SLURM_TMPDIR # if working on a SLURM cluster (in case the variable $SLURM_TMPDIR is not automatically defined by the SLURM manager, the temporary directory would usually have to be on the /scratch directory, see with the cluster's user instructions)

cd $path_to_tmp

#### COPY all the FILES in the working directory
echo "COPYING FILES";

echo "copying fasta reference"
scp $path_to_ref/$reference_fasta_file $path_to_tmp
echo "The reference file used is "$reference_fasta_file
echo "done copying fasta reference"

echo "copying data-related files"
scp $path_to_dir_in/$analysis_ID/namelist_$analysis_ID".txt" $path_to_tmp
scp $path_to_dir_in/$analysis_ID/input_fastq.txt $path_to_tmp
scp $path_to_dir_in/$analysis_ID/files_renaming.txt $path_to_tmp
# Windows users: format text files properly 
dos2unix *.txt
echo "done copying data-related files"

echo "copying fastqs";
# copy one by one:
# sh input_fastq.txt 
# parrallel copy using input_fastq.txt file:
# !!! ADJUST THE -j parameter according to the number of CPUs you want to be used !!!
parallel -j 4 < input_fastq.txt 

echo "done copying fastqs";
echo "DONE COPYING ALL FILES";

echo "GUNZIPPING files"
# In case your .fastq are compressed (.fastq.gz):
# gunzip fastqs one by one:
# gunzip *.gz 
# in parrallel :
# !!! ADJUST THE -j parameter according to the number of CPUs you want to be used !!!
ls *.gz | parallel -j 4 gunzip 
echo "DONE gunzipping files"

#Renames files in order to have file names corresponding to the list in namelist.txt
echo "renaming files"
sh files_renaming.txt
echo "done renaming files"

###################################################
#### 2. HybPiper assemble & intronerate
###################################################
cd $path_to_tmp

echo "Starting HybPiper assemble and intronerate";

# rename namelist.txt
mv $path_to_tmp/namelist_$analysis_ID".txt" $path_to_tmp/namelist.txt

rm hybpiper_parallel.txt
touch hybpiper_parallel.txt

while read name;
do 
  echo "hybpiper assemble -t_aa $reference_fasta_file -r $name*.fastq --prefix $name --cpu 2 --diamond --run_intronerate --no_stitched_contig;" >> hybpiper_parallel.txt
done < namelist.txt

parallel -j 4 < hybpiper_parallel.txt

echo "Done HybPiper assemble and intronerate";

###################################################
#### 3. Summary statistics & visualizing results
###################################################

echo "Starting computing summary statistics for GENES";
hybpiper stats -t_aa $reference_fasta_file --seq_lengths_filename genes_sequences_lengths --stats_filename hybpiper_genes_statistics gene namelist.txt
echo "Done computing summary statistics";

echo "Starting computing summary statistics for SUPERCONTIGS";
hybpiper stats -t_aa $reference_fasta_file --seq_lengths_filename supercontigs_sequences_lengths --stats_filename hybpiper_supercontigs_statistics supercontig namelist.txt
echo "Done computing summary statistics";

echo "Starting visualizing results with HybPiper script";
hybpiper recovery_heatmap --heatmap_dpi 300 --heatmap_filetype pdf --heatmap_filename recovery_heatmap_exons genes_sequences_lengths.tsv
hybpiper recovery_heatmap --heatmap_dpi 300 --heatmap_filetype pdf --heatmap_filename recovery_heatmap_supercontigs supercontigs_sequences_lengths.tsv
echo "Done visualizing results";

##################################################
#### 4. Clean and transfer to output
##################################################
# fastq files can take up a lot of space in the working directory so you may want to remove them
# but make sure they are still safely stored in a storing directory
rm $path_to_tmp/*.fastq

## if on a cluster: make output folder in home directory
# mkdir $path_to_dir_out
# scp -rp $path_to_tmp/* $path_to_dir_out/ #copy everything
