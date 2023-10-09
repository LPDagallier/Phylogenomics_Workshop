#!/bin/bash

##########################################################
############                                  ############
############      ALIGNMENT AND TRIMMING      ############
############                                  ############
##########################################################

###################################################
#### 1. Preparation 
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed
analysis_ID="example_analysis_01"
step_ID="hybpiper2_exons_align_w_refs"

# Input directory must contain ONLY the HybPiper output fastas
# Ensure formatted is correct (supercontigs introduce exon names into headers which can cause problems downstream)
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_extract/retrieved_exons/formatted_fastas";

# REFERENCE FILE:
path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FNA"

# OUTPUTS:
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/$analysis_ID"_"$step_ID";

# DEFINE TEMPORARY DIRECTORY:
path_to_tmp=$path_to_dir_out # if working locally
mkdir $path_to_tmp
cd $path_to_tmp
	
#### COPY all the FILES in the working directory
echo "Transfering fasta files to working directory";
scp -r $path_to_dir_in/* $path_to_tmp
echo "done copying files";
# remove empty files
find . -type f -empty -delete

###################################################
#### 2. Gathering reference sequences
###################################################

echo "Starting retrieving and concatenating reference sequences for ...";
rename '.FNA' '_w_refs.FNA' *
ls -1 *_w_refs.FNA | sed 's/_w_refs.FNA//g' | sort | uniq | \
parallel -j4 "echo {}; seqkit grep -w0 -nrp -{} $path_to_ref/$reference_fasta_file >> {}_w_refs.FNA;"
mkdir w_refs
mv *w_refs.FNA w_refs

echo "... done gathering reference sequences";

###################################################
#### 3. Align fastas using MAFFT
###################################################

cd $path_to_tmp/w_refs
echo "Starting alignment with MAFFT for...";

ls -1 *_w_refs.FNA | \
parallel -j4  "echo {}; mafft --thread $SLURM_CPUS_PER_TASK --quiet --auto {} > aligned.{}"

echo "...done alignment";

###################################################
#### 4. Remove reference sequences
###################################################

cd $path_to_tmp/w_refs
echo "Starting removing reference sequences ...";

ls -1 aligned.*_w_refs.FNA | sed 's/_w_refs.FNA//g' | sed 's/aligned.//g' | \
parallel -j4 "echo {}; seqkit grep -w0 -v -nrp -{} aligned.{}_w_refs.FNA > aligned.{}.FNA"

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
parallel -j4 "echo Trimming {}; clipkit {} -m smart-gap;"

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
parallel -j4 "echo Trimming {}; trimal -in {} -out {}.trimal -automated1;"

mkdir trimal
mv *.trimal trimal
cd trimal
rename -v '.FNA.trimal' '.FNA' *

echo "done trimming";

