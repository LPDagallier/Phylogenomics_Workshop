#!/bin/bash
#################################################################
############                             ########################
############      HYBPIPER EXTRACT       ########################
############                             ########################
#################################################################

###################################################
#### 1. Preparation (1.1. OR 1.2)
###################################################

##### 1.1. In cases the list of sample is the SAME as in the previous assembly step
###################################################
#### Set up PATHS and VARIABLES
analysis_ID="example_analysis_01"
path_to_assemble="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_assemble/";
path_to_tmp=$path_to_assemble
reference_fasta_file="target_reference.FAA"

##### 1.2. In cases the list of sample is DIFFERENT from the previous assembly step
###################################################
#### 1.2.1 Set up PATHS and VARIABLES
analysis_ID="<new_analysis_id>"
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA"

path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FAA"

step_ID="hybpiper2_extract_no_stiched"
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_"$step_ID/;

path_to_tmp=$path_to_dir_out # if working locally
mkdir $path_to_tmp
# path_to_tmp=$SLURM_TMPDIR # if working on a SLURM cluster (in case the variable $SLURM_TMPDIR is not automatically defined by the SLURM manager, the temporary directory would usually have to be on the /scratch directory, see with the cluster's user instructions)

#### 1.2.2 COPY all the FILES in the working directory
cd $path_to_tmp
scp $path_to_ref/$reference_fasta_file $path_to_tmp
scp $path_to_dir_in/$analysis_ID/namelist_$analysis_ID".txt" $path_to_tmp
mv $path_to_tmp/namelist_$analysis_ID".txt" $path_to_tmp/namelist.txt
scp $path_to_dir_in/$analysis_ID/input_assemblies.txt $path_to_tmp
dos2unix *.txt

# Copy the assemblies
## one by one:
# sh input_assemblies.txt 
## in parrallel :
## !!! ADJUST THE -j parameter according to the number of CPUs you want to be used !!!
parallel -j 4 < input_assemblies.txt 

#### 1.2.3 [optional] re-compute the assembly statistics

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

###################################################
#### 2. hybpiper retrieve_sequences
###################################################
cd $path_to_tmp

echo "Retrieve sequences"

mkdir retrieved_exons
hybpiper retrieve_sequences dna -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_exons

mkdir retrieved_introns
hybpiper retrieve_sequences intron -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_introns

mkdir retrieved_supercontigs
hybpiper retrieve_sequences supercontig -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_supercontigs

# experimental:
mkdir retrieved_aa
hybpiper retrieve_sequences aa -t_aa $reference_fasta_file --sample_names namelist.txt --fasta_dir retrieved_aa

echo "Done retrieving sequences"

####################################################
##### 3. Post HybPiper file formatting
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
## if on a cluster: make output folder in home directory
# mkdir $path_to_dir_out
# scp -rp $path_to_tmp/* $path_to_dir_out/
# 
echo "FINISHED";
