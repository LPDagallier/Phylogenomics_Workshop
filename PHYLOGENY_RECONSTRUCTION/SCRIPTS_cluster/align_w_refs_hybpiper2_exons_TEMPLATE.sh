#!/bin/bash

############      SLURM CONFIGURATION      ###################
#SBATCH --job-name=align_w_refs_hybpiper2_exons_example_analysis_01
#SBATCH --account=<INSERT ACCOUNT e.g.: soltis>
#SBATCH --qos=<INSERT QUEUE NAME e.g.: soltis>
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=2
#SBATCH --mem=32gb 
#SBATCH --time=4-00:00:00
#SBATCH --mail-user=<INSERT YOUR EMAIL>
#SBATCH --mail-type=ALL
#SBATCH --output=slurm-%x-%j.out
############################################################

echo "JOB CONFIGURATION"
echo "Job ID: " $SLURM_JOB_ID
echo "Name of the job: " $SLURM_JOB_NAME
echo "Node(s) allocated to the job: " $SLURM_JOB_NODELIST
echo "Number of nodes allocated: " $SLURM_JOB_NUM_NODES
echo "Memory allocated per node: " $SBATCH_MEM_PER_NODE
echo "Number of CPU tasks: " $SLURM_NTASKS
echo "Amount of CPU per tasks: " $SLURM_CPUS_PER_TASK
echo "Amount of RAM per tasks: " $SBATCH_MEM_PER_CPU
echo "Directory from which sbatch was invoked: " $SLURM_SUBMIT_DIR
echo "Temporary folder in which the job runs: " $SLURM_TMPDIR

###################################################
#### 1. Preparation of files and transfer to cluster
###################################################

#### Make variables with paths to directories
analysis_ID="example_analysis_01"
step_ID="hybpiper2_exons_align_w_refs"

# Input directory must contain ONLY the HybPiper output fastas
# Ensure formatted is correct (supercontigs introduce exon names into headers which can cause problems downstream)
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_extract/retrieved_exons/formatted_fastas";

path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FNA"

# change output folder name
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/$analysis_ID"_"$step_ID"_"$SLURM_JOB_ID/";

path_to_tmp=$SLURM_TMPDIR
cd $path_to_tmp
	
#### Create folders on node 
echo "Transfering files to node";
scp -r $path_to_dir_in/* $path_to_tmp
echo "done copying files";
# remove empty files
find . -type f -empty -delete

####
#load modules
####

module load parallel
module load mafft/7.490
# module load gblocks
module load clipkit/1.3.0
module load trimal/1.4.1
module load seqkit

###################################################
#### 2. Gathering reference sequences
###################################################

echo "Starting retrieving and concatenating reference sequences for ...";
rename '.FNA' '_w_refs.FNA' *
ls -1 *_w_refs.FNA | sed 's/_w_refs.FNA//g' | sort | uniq | \
parallel -j$SLURM_NTASKS "echo {}; seqkit grep -w0 -nrp -{} $path_to_ref/$reference_fasta_file >> {}_w_refs.FNA;"
# parallel -j16 "echo {}; seqkit grep -w0 -nrp -{} $path_to_ref/$reference_fasta_file >> {}_w_refs.FNA;" 
mkdir w_refs
mv *w_refs.FNA w_refs

echo "... done gathering reference sequences";

###################################################
#### 3. Align fastas using MAFFT
###################################################

cd $path_to_tmp/w_refs
echo "Starting alignment with MAFFT for...";
ls -1 *_w_refs.FNA | \
parallel -j$SLURM_NTASKS  "echo {}; mafft --thread $SLURM_CPUS_PER_TASK --quiet --auto {} > aligned.{}"
# parallel -j8  "echo {}; mafft --thread 2 --quiet --auto {} > aligned.{}"

echo "...done alignment";

###################################################
#### 4. Remove reference sequences
###################################################

cd $path_to_tmp/w_refs
echo "Starting removing reference sequences ...";

ls -1 aligned.*_w_refs.FNA | sed 's/_w_refs.FNA//g' | sed 's/aligned.//g' | \
parallel -j$SLURM_NTASKS "echo {}; seqkit grep -w0 -v -nrp -{} aligned.{}_w_refs.FNA > aligned.{}.FNA"
# parallel -j8 "echo {}; seqkit grep -w0 -v -nrp -{} aligned.{}_w_refs.FNA > aligned.{}.FNA"

echo "...done removing reference sequences";

mkdir alignments_including_refs
mv aligned.*w_refs.FNA alignments_including_refs
rm *_w_refs.FNA

####################################################
##### 5a. Trim using ClipKIT
####################################################

cd $path_to_tmp/w_refs
echo "starting trimming with ClipKit";

ls -1 aligned.*.FNA | \
parallel -j$SLURM_NTASKS "echo Trimming {}; clipkit {} -m smart-gap;"

mkdir clipkit
mv *clipkit clipkit
cd clipkit
rename -v '.FNA.clipkit' '.FNA' *

echo "done trimming";

####################################################
##### 5b. Trim using TrimAl
####################################################

cd $path_to_tmp/w_refs
echo "starting trimming with TrimAl";

ls -1 aligned.*.FNA | \
parallel -j$SLURM_NTASKS "echo Trimming {}; trimal -in {} -out {}.trimal -automated1;"

mkdir trimal
mv *.trimal trimal
cd trimal
rename -v '.FNA.trimal' '.FNA' *

echo "done trimming";

##################################################
#### 6. Transfer
##################################################
#Transfer output data

echo "Transfering data from node to blue storage";

mkdir $path_to_dir_out

scp -rp $path_to_tmp/* $path_to_dir_out/

echo "done transfering, FINISHED";

# All the data are automatically deleted on the node by SLURM
