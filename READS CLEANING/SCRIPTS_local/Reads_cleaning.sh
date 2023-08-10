#!/bin/bash
#################################################################
############                             ########################
############       READS CLEANING        ########################
############                             ########################
#################################################################

###################################################
#### 1. Preparation 
###################################################

#### Set up PATHS and VARIABLES
# change depending on what data is being analysed

# The name of the plate (or set of samples):
plate_to_clean="<plate_ID>"

# The path to the raw (i.e. not cleaned) reads:
path_to_plate_dir="<path_to_raw_reads>/"$plate_to_clean

# The path to the reference file (used to compute some statistics):
path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FNA"

# The path to the R scripts for plotting statistics:
path_to_R_script="<base_directory>/DATA_ANALYSES/READS_CLEANING/R"

# The output directory:
path_to_dir_out="<base_directory>/DATA_ANALYSES/READS_CLEANING/"$plate_to_clean;

# Temporary directory for local users:
path_to_tmp=$path_to_dir_out

cd $path_to_tmp

#### COPY all the FILES in the working directory
echo "COPYING FILES";
scp -r $path_to_plate_dir $path_to_tmp
cd $plate_to_clean
echo "DONE COPYING ALL FILES";

###################################################
#### 2. Pre Cleaning steps
###################################################
cd $path_to_tmp

# RUN THIS IF THE SAMPLES WERE SEQUENCED ON 2 DIFFERENT LANES (L001 and L002)
for i in *_L001_R1_001.fastq.gz ;
do pattern=${i%%_L001_R1_001.fastq.gz*} ; 
echo $pattern;
cat ${pattern}_L001_R1_001.fastq.gz ${pattern}_L002_R1_001.fastq.gz > ${pattern}_R1_001.fastq.gz;
cat ${pattern}_L001_R2_001.fastq.gz ${pattern}_L002_R2_001.fastq.gz > ${pattern}_R2_001.fastq.gz;
done
rm *_L001_*  *_L002_*

for i in *_L001_R1.fastq.gz ;
do pattern=${i%%_L001_R1.fastq.gz*} ; 
echo $pattern;
cat ${pattern}_L001_R1.fastq.gz ${pattern}_L002_R1.fastq.gz > ${pattern}_R1_001.fastq.gz;
cat ${pattern}_L001_R2.fastq.gz ${pattern}_L002_R2.fastq.gz > ${pattern}_R2_001.fastq.gz;
done
rm *_L001_*  *_L002_*


###################################################
#### 3. Reads cleaning
###################################################

echo "Starting cleaning reads";

for i in `ls *_R1_001.fastq.gz` ;
do pattern=${i%%_R1*} ; 
echo "Cleaning reads for "$pattern ;
fastp -i ${pattern}_R1_001.fastq.gz -I ${pattern}_R2_001.fastq.gz -o ${pattern}_CLEAN_R1.fastq.gz -O ${pattern}_CLEAN_R2.fastq.gz -j ${pattern}_report.json -h ${pattern}_report.html -e 30 -l 35 -q 15 -u 40 -y -D -c -w 2 ;
done

mkdir clean_reads
mv *CLEAN* ./clean_reads

mkdir reports
mv *report.* ./reports

echo "Done cleaning reads";

##################################################
#### 4. Transfer the output
##################################################

mkdir $path_to_dir_out
scp -rp $path_to_tmp/clean_reads $path_to_dir_out/
scp -rp $path_to_tmp/reports $path_to_dir_out/

##################################################
#### 5. Sequencing statistics
##################################################

# Number of clean paired R1 and R2 reads
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

# Alignment and coverage statistics
## Alignment of the reads to the reference with Minimap
cd ./clean_reads
scp $path_to_ref/$reference_fasta_file ./

for i in `ls *CLEAN*.fastq.gz` ;
do pattern=${i%%CLEAN*} ; 
echo $pattern;
minimap2 -ax sr -t 2 -B 1 $reference_fasta_file ${pattern}CLEAN_R1.fastq.gz ${pattern}CLEAN_R2.fastq.gz > ${pattern}CLEAN_minimap.sam;
done

# Compress the .sam files into .bam files (gain of space)
for i in *.sam ;
  do pattern=${i%%.sam} ;
  if [ ! -f "${pattern}.bam" ]; then
    echo ${pattern};
    samtools view -@ 1 -bh $i > ${pattern}.bam;
  fi;
done

# Sort the reads in the alignments and create an index for the alignments (for samtools to be faster).
for i in *.bam ; do pattern=${i%%.bam} ; echo ${pattern}; samtools sort -@ 2 -o ${pattern}_sort.bam $i ; done
for i in *sort.bam ; do samtools index $i ; done

#### Number of mapped alignments and unmapped reads
# Count mapped reads
samtools view -F 0x4 -c EXAMPLE_sort.bam
# write a file with only the mapped reads
samtools view -F 0x4 EXAMPLE_sort.bam -o EXAMPLE_sort_mapped_reads.bam
# Count the unmapped reads
samtools view -f 0x4 -c EXAMPLE_sort.bam

#### Breadth and depth of coverage with BedTools

# coverage 1X+
genomeCoverageBed -ibam EXAMPLE_sort_mapped_reads.bam -max 1 | grep -e 'genome\s10' | grep -o '0\..\+'
# coverage 3X+
genomeCoverageBed -ibam EXAMPLE_sort_mapped_reads.bam -max 3 | grep -e 'genome\s3' | grep -o '0\..\+'
# coverage 10X+
genomeCoverageBed -ibam EXAMPLE_sort_mapped_reads.bam -max 10 | grep -e 'genome\s1' | grep -o '0\..\+'

genomeCoverageBed -ibam EXAMPLE_sort_mapped_reads.bam -d > EXAMPLE_reference_coverage.txt
cat EXAMPLE_reference_coverage.txt | awk '{sum+=$3; sumsq+=$3*$3} END { print "Average=",sum/NR; print "Stdev=",sqrt(sumsq/NR - (sum/NR)*(sum/NR))}' > temp_output.txt
average=$(grep -e 'Average=\s' temp_output.txt | sed 's/Average=\s//')
stdev=$(grep -e 'Stdev=\s' temp_output.txt | sed 's/Stdev=\s//')
echo $average
echo $stdev

#### Export the statistics and coverage plots
rm mapping_statistics.csv # remove the file in case it already exists
touch mapping_statistics.csv # creates an empty file

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

# Plot heatmaps
cd ../reports/ref_coverage
scp $path_to_R_script/post_cleaning_coverage_heatmap.R ./
module load R/4.1
Rscript post_cleaning_coverage_heatmap.R

#Clean the `report` folder:
rm *.R *.txt
cd ../
mkdir ./fastp_reports
mv *.html ./fastp_reports
rm *.json


## Clean the output directory
cd $path_to_dir_out/clean_reads/
rm *.sam *.bam *.bai *.R *.fa *.txt