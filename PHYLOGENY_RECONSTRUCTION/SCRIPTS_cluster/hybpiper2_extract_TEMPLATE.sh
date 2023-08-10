#!/bin/bash

############      SLURM CONFIGURATION      ###################
#SBATCH --job-name=hybpiper2_extract_no_stitched_example_analysis_01
#SBATCH --account=<INSERT ACCOUNT e.g.: soltis>
#SBATCH --qos=<INSERT QUEUE NAME e.g.: soltis>
#SBATCH --cpus-per-task=8 
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32gb 
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
#### 1. Preparation (choose 1.1 OR 1.2)
###################################################
###################################################
######## 1.1. In cases the list of sample is the SAME as in the previous assembly step
###################################################
analysis_ID="example_analysis_01"
path_to_assemble="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_assemble_no_stitched_<previous_job_ID>/";
path_to_tmp=$path_to_assemble
reference_fasta_file="target_reference.FAA"

###################################################
######## 1.2. In cases the list of sample is DIFFERENT from the previous assembly step
###################################################
#### 1.2.1 Set up PATHS and VARIABLES
analysis_ID="<new_analysis_id>"
step_ID="hybpiper2_extract"

path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA"

path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FAA"

# OUTPUT FOLDER
# where the ouptputs will be stored
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_"$step_ID"_"$SLURM_JOB_ID/;

path_to_tmp=$SLURM_TMPDIR

#### 1.2.2 COPY all the FILES in the working directory
cd $path_to_tmp
scp $path_to_ref/$reference_fasta_file $path_to_tmp
scp $path_to_dir_in/$analysis_ID/namelist_$analysis_ID".txt" $path_to_tmp
mv $path_to_tmp/namelist_$analysis_ID".txt" $path_to_tmp/namelist.txt
scp $path_to_dir_in/$analysis_ID/input_assemblies.txt $path_to_tmp
dos2unix *.txt
# !!! ADJUST THE -j parameter according to the --cpus-per-task SLURM parameter !!!
module load parallel
echo "copying assemblies"
parallel -j 8 < input_assemblies.txt 
echo "done copying assemblies"

#### 1.2.3 [optional] re-compute the assembly statistics
module load hybpiper/2.1.1
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


####################################################
#### 2. Retrieve sequences
####################################################
cd $path_to_tmp
module load hybpiper/2.1.1

echo "Retrieve sequences"

mkdir retrieved_exons
hybpiper retrieve_sequences dna -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_exons

mkdir retrieved_introns
hybpiper retrieve_sequences intron -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_introns

mkdir retrieved_supercontigs
hybpiper retrieve_sequences supercontig -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_supercontigs

mkdir retrieved_aa
hybpiper retrieve_sequences aa -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_aa

echo "Done retrieving sequences"

####################################################
#### 3. Post HybPiper file formatting
####################################################
echo "Starting post HybPiper file formatting..."

echo "... for exons";
cd $path_to_tmp/retrieved_exons/
mkdir formatted_fastas
cp *.FNA formatted_fastas
cd formatted_fastas
find . -type f -empty -delete
ls -1 ./ | \
while read sample; \
do 
	cat $sample | awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' > $sample.oneline
done
rm *.FNA
rename '.oneline' '' *
sed -i '/^>/s/[[:space:]].*//g' * # removes everything after a space in lines begining with >
sed -i '/^$/d' * #removes empty lines

echo "... for supercontigs";
cd $path_to_tmp/retrieved_supercontigs/
mkdir formatted_fastas
cp *.fasta formatted_fastas
cd formatted_fastas
find . -type f -empty -delete
ls -1 ./ | \
while read sample; \
do 
	cat $sample | awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' > $sample.oneline
done
rm *.fasta
rename '.fasta.oneline' '.FNA' *
sed -i '/^>/s/[[:space:]].*//g' * # removes everything after a space in lines begining with >
sed -i '/^$/d' * #removes empty lines

echo "Done post HybPiper file formatting"

##################################################
#### 4. Transfer to output (ONLY WHEN $path_to_tmp different from $path_to_dir_out)
##################################################
echo "Transfert output from tmp dir to output dir";
## if on a cluster: make output folder in home directory
mkdir $path_to_dir_out

# copy everything (might be long because it also copies the assemblies)
scp -rp $path_to_tmp/* $path_to_dir_out/

# copy only the retrieved sequences and stat files
# scp -rp $path_to_tmp/retrieved* $path_to_dir_out/
# scp -rp $path_to_tmp/*.pdf $path_to_dir_out/
# scp -rp $path_to_tmp/*.tsv $path_to_dir_out/

echo "FINISHED";

# All the data are automatically deleted on the scratch by SLURM