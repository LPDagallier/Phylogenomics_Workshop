#!/bin/bash

############      SLURM CONFIGURATION      ###################
#SBATCH --job-name=hybpiper2_assemble_no_stitched_example_analysis_01
#SBATCH --account=<INSERT ACCOUNT e.g.: soltis>
#SBATCH --qos=<INSERT QUEUE NAME e.g.: soltis>
#SBATCH --cpus-per-task=8 
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32gb 
#SBATCH --time=4-00:00:00
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
#### 1. Preparation of files and transfer to cluster
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed
# The analyse identifier that will be used as a preffix or suffix in scripts, file names and/or folder names
# must be unique to THIS run of analysis (that is this combination of samples, reference file, HYbPiper parameters, etc.)
analysis_ID="example_analysis_01"
step_ID="hybpiper2_no_stitched"

# REFERENCE FILE:
path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FAA"

# DATA-RELATED FILES:
# Prepare (locally) the following files:
#namelist.txt: contains the sample names that will be analysed
#input_fastq: contains the copying comands for batch-copy the fastq files
#files_renaming.txt: contains the renaming comands for batch-rename the fastq files
#These files have to be in a folder that has the same name as analysis_ID situated in path_to_dir_in:
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA";

# OUTPUT FOLDER
# where the ouptputs will be stored
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_"$step_ID"_"$SLURM_JOB_ID/;

#temporary folder (intermediate files)
#make temporary directory to store files/run analyses in
# this will be automatically deleted at the end
path_to_tmp=$SLURM_TMPDIR

cd $path_to_tmp

module load parallel

# COPY FILES
echo "COPYING FILES";

echo "copying fasta reference"
scp $path_to_ref/$reference_fasta_file $path_to_tmp
echo "The reference file used is "$reference_fasta_file
echo "done copying fasta reference"

echo "copying data-related files"
scp $path_to_dir_in/$analysis_ID/namelist_$analysis_ID.txt $path_to_tmp
scp $path_to_dir_in/$analysis_ID/input_fastq.txt $path_to_tmp
scp $path_to_dir_in/$analysis_ID/files_renaming.txt $path_to_tmp
# format text files properly (sometimes windows does weird things on txt files, making them unix-incompatible)
dos2unix *.txt
echo "done copying data-related files"

echo "copying fastqs";
# copy one by one
# sh input_fastq.txt 
# parrallel copy using txt file
# !!! ADJUST THE -j parameter according to the --cpus-per-task SLURM option !!!
parallel -j 8 < input_fastq.txt 

echo "done copying fastqs";
echo "DONE COPYING ALL FILES";

# gunzip fastqs
# in parrallel :
# !!! ADJUST THE -j parameter according to the --cpus-per-task SLURM option !!!
echo "gunzipping files"
ls *.gz | parallel -j 8 gunzip 
echo "done gunzipping files"

#Renames files in order to have file names corresponding to the list in namelist.txt
echo "renaming files"
sh files_renaming.txt
echo "done renaming files"

#list the file in the log file to allow checks
echo "LIST OF THE FILES:"
ls

# load module HybPiper
module load hybpiper/2.1.1

###################################################
#### 2. HybPiper assemble & intronerate
###################################################
cd $path_to_tmp

echo "Starting HybPiper assemble and intronerate";

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
#### 4. Transfer
##################################################

echo "Transfert data node -> blue storage";

# make output folder in home directory
mkdir $path_to_dir_out

#fastq files can take up a lot of space so you may want to remove them
rm $path_to_tmp/*.fastq

# copy everything
scp -rp $path_to_tmp/* $path_to_dir_out/

echo "done moving, FINISHED";

# All the data are automatically deleted on the node by SLURM