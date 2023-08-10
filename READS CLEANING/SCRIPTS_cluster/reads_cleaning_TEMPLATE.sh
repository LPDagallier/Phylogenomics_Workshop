#!/bin/bash

############      SLURM CONFIGURATION      ###################

#SBATCH --job-name=reads_cleaning_example_analysis_01
#SBATCH --account=<INSERT ACCOUNT e.g.: soltis>
#SBATCH --qos=<INSERT QUEUE NAME e.g.: soltis>
#SBATCH --cpus-per-task=2 
#SBATCH --ntasks-per-node=1
#SBATCH --mem=8gb 
#SBATCH --time=24:00:00
#SBATCH --mail-user=<INSERT YOUR EMAIL>
#SBATCH --mail-type=ALL

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
#### 0 Preparation of files and transfer to cluster
###################################################

#### Set the correct path and variable names ####

plate_to_clean="example_analysis_01"
path_to_plate_dir="/orange/soltis/ldefreitasbacci/plates/target_capture/"$plate_to_clean
path_to_fastp="<base_directory>/PROGRAMS/fastp"
path_to_R_scripts="/<base_directory>/SCRIPTS/"

path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
ref_file="Melastomataceae_689_clean.fa"

#### #### #### #### #### #### #### #### #### ####

# go into the temporary working directory:
path_to_tmp="<base_directory>/DATA_ANALYSES/READS_CLEANING"
echo "Temporary working diretory is:" $path_to_tmp
cd $path_to_tmp
mkdir $plate_to_clean

# copy from orange storage the data to clean
echo "Copying raw reads for plate" $plate_to_clean
scp -r $path_to_plate_dir/raw_reads/*.fastq* $path_to_tmp/$plate_to_clean
cd $plate_to_clean

# copy the fastp program
scp $path_to_fastp ./

###################################################
#### 1 Pre cleaning step
###################################################
# - first verify that each sample has a R1 and a R2 file
# - if two lanes: merge reads from lane 1 with lane 2 and remove the lane suffix (L001 and L002)
# - if no 001 suffix, add it
echo "1. Pre cleaning step"

echo "Verifying the existence of both R1 and R2 files for every sample (will cancel the job if one of R1 or R2 is missing for any sample)"

cancelJob="FASLE"
for i in *R1*.fastq*;
  do
  R2_file=${i/_R1_/_R2_}
    if [ ! -e $R2_file ];
    then
      echo "WARNING:" $R2_file" does not exist. Consider stopping the cleaning process.";
      cancelJob="TRUE";
    fi
done
for i in *R2*.fastq*;
  do
  R1_file=${i/_R2_/_R1_}
    if [ ! -e $R1_file ];
    then
      echo "WARNING:" $R1_file" does not exist. Consider stopping the cleaning process.";
      cancelJob="TRUE";
    fi
done

if [ $cancelJob == "TRUE" ];
then
  echo "THIS JOB WILL CANCEL.";
  scancel $SLURM_JOB_ID
fi

echo "Done verifying the existence of both R1 and R2 files for every sample.";
# echo "Merging files from Lane 1 and Lane 2 for every sample, if needed.";
# 
# for i in *_L002_R1*.fastq.gz ;
#   do
#     if [[ $i == *"001."* ]] ;
#     then 
#       pattern=${i%%_L002_R1_001.fastq.gz*} ; 
#       echo $pattern;
#       cat ${pattern}_L001_R1_001.fastq.gz ${pattern}_L002_R1_001.fastq.gz > ${pattern}_R1_001.fastq.gz;
#       cat ${pattern}_L001_R2_001.fastq.gz ${pattern}_L002_R2_001.fastq.gz > ${pattern}_R2_001.fastq.gz;
#     fi
#     
#     if [[ ! $i == *"001."* ]] ;
#     then 
#       pattern=${i%%_L002_R1.fastq.gz*} ; 
#       echo $pattern;
#       cat ${pattern}_L001_R1.fastq.gz ${pattern}_L002_R1.fastq.gz > ${pattern}_R1_001.fastq.gz;
#       cat ${pattern}_L001_R2.fastq.gz ${pattern}_L002_R2.fastq.gz > ${pattern}_R2_001.fastq.gz;
#     fi
# done
# 
# rm *_L001_*  *_L002_*
# 
# echo "Done merging"

###################################################
#### 2 Clean reads with fastp
###################################################

#############
#### 2a fastp
# module load fastp/0.22.0
echo "2. Clean reads with fastp"

for i in `ls *_R1_001.fastq.gz` ;
do pattern=${i%%_R1*} ; 
echo $pattern ;
./fastp -i ${pattern}_R1_001.fastq.gz -I ${pattern}_R2_001.fastq.gz -o ${pattern}_CLEAN_R1.fastq.gz -O ${pattern}_CLEAN_R2.fastq.gz -j ${pattern}_report.json -h ${pattern}_report.html -e 30 -l 35 -q 15 -u 40 -y -D -c -w 2 ;
done

mkdir clean_reads
mv *CLEAN* ./clean_reads

mkdir reports
mv *report.* ./reports

#############
#### 2b Number of clean paired R1 and R2 reads
cd ./reports
rm clean_reads_true_count.csv # remove the file in case it already exists
echo 'name, raw_reads, clean_reads' > clean_reads_true_count.csv
for i in `ls *report.json` ;
do pattern=${i%%_report.json} ;
raw_reads=$(grep '"before_filtering"' -A1 $i | grep -E '[[:digit:]]*' -o)
clean_reads=$(grep '"after_filtering"' -A1 $i | grep -E '[[:digit:]]*' -o)
echo $pattern, $raw_reads, $clean_reads >> clean_reads_true_count.csv
done
cd ../

###################################################
#### 3 Compute sequencing statistics
###################################################
echo "3. Compute sequencing statistics"

#############
#### 3a Alignment of the reads to the reference
# choose between Minimap and BWA below
# MINIMAP
echo "run Minimap2"
module load minimap2/2.24
cd ./clean_reads
scp $path_to_ref/$ref_file ./
for i in `ls *CLEAN*.fastq.gz` ;
do pattern=${i%%CLEAN*} ; 
echo $pattern;
minimap2 -ax sr -t 2 -B 1 $ref_file ${pattern}CLEAN_R1.fastq.gz ${pattern}CLEAN_R2.fastq.gz > ${pattern}CLEAN_minimap.sam;
done

# BWA
#echo "run BWA"
#module load bwa/0.7.17
#cd ./clean_reads
#scp $path_to_ref/$ref_file ./
#bwa index $ref_file
#for i in `ls *CLEAN*.fastq` ;
#do pattern=${i%%CLEAN*} ; 
#bwa mem -B 1 -t 8 $ref_file ${pattern}CLEAN_R1.fastq ${pattern}CLEAN_R2.fastq >${pattern}CLEAN_BWA.sam;
#done

echo "run Samtools"
# Compress the .sam files into .bam files (gain of space)
module load samtools/1.12
# the command is executed only if the .bam file doesn't already exists
echo "Samtools: compress to .bam"
for i in *.sam ;
  do pattern=${i%%.sam} ;
  if [ ! -f "${pattern}.bam" ]; then
    echo ${pattern};
    samtools view -@ 1 -bh $i > ${pattern}.bam;
  fi;
done

#Sort the reads in the alignments and create an index for the alignments (for samtools to be faster).
echo "Samtools: sort reads and index"
for i in *.bam ;
  do pattern=${i%%.bam} ;
  echo ${pattern};
  samtools sort -@ 2 -o ${pattern}_sort.bam $i ;
done

for i in *sort.bam ;
  do samtools index $i ;
done

#############
#### 3b Coverage statistics
# write the stats in a file called mapping_statistics.csv

rm mapping_statistics.csv # remove the file in case it already exists
touch mapping_statistics.csv

module load samtools/1.12
module load bedtools/2.30.0

echo "Write the coverage statistics into mapping_statistics.csv"

echo 'name, mapped_alignments, unmapped_reads, cov1x, cov3x, cov10x, average, stdev' > mapping_statistics.csv
for i in *sort.bam ;
  do pattern=${i%%.bam} ;
  echo ${pattern};
  mapped=$(samtools view -@ 1 -F 0x4 -c $i)
  samtools view -@ 1 -F 0x4 $i -o $pattern'_mapped_reads.bam'
  unmapped=$(samtools view -@ 1 -f 0x4 -c $i)
  cov1x=$(genomeCoverageBed -ibam $pattern'_mapped_reads.bam' -max 1 | grep -e 'genome\s1' | grep -o '0\..\+')
  cov3x=$(genomeCoverageBed -ibam $pattern'_mapped_reads.bam' -max 3 | grep -e 'genome\s3' | grep -o '0\..\+')
  cov10x=$(genomeCoverageBed -ibam $pattern'_mapped_reads.bam' -max 10 | grep -e 'genome\s10' | grep -o '0\..\+')
  genomeCoverageBed -ibam $pattern'_mapped_reads.bam' -d > $pattern'_reference_coverage.txt'
  cat $pattern'_reference_coverage.txt' | awk '{sum+=$3; sumsq+=$3*$3} END { print "Average=",sum/NR; print "Stdev=",sqrt(sumsq/NR - (sum/NR)*(sum/NR))}' > temp_output.txt
  average=$(grep -e 'Average=\s' temp_output.txt | sed 's/Average=\s//')
  stdev=$(grep -e 'Stdev=\s' temp_output.txt | sed 's/Stdev=\s//')
  rm temp_output.txt
  echo $pattern'_mapped_reads', $mapped, $unmapped, $cov1x, $cov3x, $cov10x, $average, $stdev >> mapping_statistics.csv
done
head mapping_statistics.csv

# Move the statistics file and other useful files into the `report` folder and sub folders.
mv mapping_statistics.csv ../reports
mkdir ../reports/ref_coverage
scp *reference_coverage.txt ../reports/ref_coverage

# Plot the heatmaps showing the average depth at each locus and coverage breadth at 1x+, 3x+ and 10x+ for the set of specimen
# copy the R scripts
echo "PLOT HEATMAPS"
cd ../reports/ref_coverage
scp $path_to_R_scripts/post_cleaning_coverage_heatmaps.R ./
module load R/4.1
echo "Run R for coverage heatmaps"
Rscript post_cleaning_coverage_heatmaps.R

# OPTIONAL: plot the coverage depth across the reference for every specimen
# to do so, change optional_plots to "TRUE"
optional_plots="FALSE"
if [ $optional_plots = TRUE ]; then
  echo "Optional plots for every specimen"
  scp $path_to_R_scripts/post_cleaning_coverage_per_specimen.R ./
  Rscript post_cleaning_coverage_per_specimen.R
  mkdir per_specimen
  mv *reference_coverage.png ./per_specimen
fi;

# Clean the `report` folder:
rm *.R *.txt
cd ../
mkdir ./fastp_reports
mv *.html ./fastp_reports
rm *.json

###################################################
#### 4 Transfer back the clean reads
###################################################
echo "transferring clean reads to" $path_to_plate_dir
mkdir $path_to_plate_dir/clean_reads
scp $path_to_tmp/$plate_to_clean/clean_reads/*CLEAN*fastq.gz $path_to_plate_dir/clean_reads
# attribute permission to read write and execute to owner and members of the group:
cd $path_to_plate_dir
chmod -R 770 clean_reads

# CLEAN ONCE EVERYTHING LOOKS GOOD
cd $path_to_tmp/$plate_to_clean/clean_reads/
rm -r *.sam *.bam *.bai *.fa *.txt
cd $path_to_tmp/$plate_to_clean/
rm -r fastp *.fastq.gz
