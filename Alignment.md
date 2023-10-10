Alignment
================

**Author**: [Léo-Paul Dagallier](https://github.com/LPDagallier)  
**Last update**: 2023-10-10

------------------------------------------------------------------------

After extracting the sequences (exons, supercontigs or multicopies
exons), we need to align them.

Here we’ll use
[MAFFT](https://mafft.cbrc.jp/alignment/software/algorithms/algorithms.html)
to align, but other program do exist
(e.g. [MUSCLE](https://drive5.com/muscle5/manual/commands.html),
[Clustal](http://www.clustal.org/),
[MACSE](https://www.agap-ge2pop.org/macse/?menu=releases)).

Sequences can be aligned “naively” or “informed” by the locus reference
sequence. As a rule of thumb, I would advise to align with the locus
reference sequence, because it is conceptually less prone to alignment
errors.

Here I’ll present only the “informed” method, but the extra steps this
method requires can easily be removed if you want to go with the “naive”
method.

## Multi-sequences alignment

### Define the paths and variables

- for the inputs:

``` bash
analysis_ID="my_analysis_ID"
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA";
path_to_dir_in="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/"$analysis_ID"_hybpiper2_extract/retrieved_exons/formatted_fastas";

path_to_ref="<base_directory>/DATASETS/PHYLOGENOMICS/target_references"
reference_fasta_file="target_reference.FNA"
```

- for the outputs:

``` bash
step_ID="hybpiper2_exons_align_w_refs"
path_to_dir_out="<base_directory>/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/$analysis_ID"_"$step_ID"/";
```

- temporary directory for local users:

``` bash
path_to_tmp=$path_to_dir_out
```

- temporary directory for cluster users: depends on the cluster manager
  and its setup (please see with your cluster documentation), e.g. for
  SLURM on HiperGator:

``` bash
path_to_tmp=$SLURM_TMPDIR
```

### Copy all the files in the working directory

Go to working directory.

``` bash
cd $path_to_tmp
```

Copy the fasta files.

``` bash
scp -r $path_to_dir_in/* $path_to_tmp
```

Remove the empty files that are sometimes created by HybPiper extract.

``` bash
find . -type f -empty -delete
```

The working directory should only contain sequences file.

### Gather reference sequences for each locus

Append the suffix “w_refs” to all the fasta files.

``` bash
rename '.FNA' '_w_refs.FNA' *
```

Extract the loci names from the list of \_w_refs.FNA files, that is list
the files (`ls -1`), remove the suffix “\_w_refs.FNA”
([`sed`](https://www.gnu.org/software/sed/manual/sed.html)), `sort` and
remove duplicate (`uniq`). For each of these extracted locus name,
extract all the sequences that contain these extracted locus name in
their own sequence name from the reference file
([`seqkit grep`](https://bioinf.shenwei.me/seqkit/usage/#grep)), and
append these extracted sequences to the corresponding \_w_refs.FNA file
(`>>`). Be careful of the names of your .FNA files; in the case other
prefix or suffix have been introduced earlier, you would need to remove
them using the [`sed`](https://www.gnu.org/software/sed/manual/sed.html)
command (`sed 's/<character string to remove>//g'`).

``` bash
for locus in $(ls -1 *_w_refs.FNA | sed 's/_w_refs.FNA//g' | sort | uniq)
do
  seqkit grep -w0 -nrp -$locus $path_to_ref/$reference_fasta_file >> $locus"_w_refs.FNA";
done
```

Note that this can be done in a faster way using the `parallel` command
(e.g. here paralleled on 4 different cores):

``` bash
ls -1 *_w_refs.FNA | sed 's/_w_refs.FNA//g' | sort | uniq | \
parallel -j4 "echo {}; seqkit grep -w0 -nrp -{} $path_to_ref/$reference_fasta_file >> {}_w_refs.FNA;"
```

Move all the “with ref” fastas to a separate subdirectory.

``` bash
mkdir w_refs
mv *w_refs.FNA w_refs
```

### Run the alignment with MAFFT

Go to the subdirectory.

``` bash
cd $path_to_tmp/w_refs
```

Alignment can be run one after the other…

``` bash
for file in $(ls -1 *_w_refs.FNA)
do
  mafft --thread 2 --quiet --auto $file > aligned.$file
done
```

… or in parallel (here on 4 different cores):

``` bash
for file in $(ls -1 *_w_refs.FNA)
do
  echo "mafft --thread 2 --quiet --auto $file > aligned.$file"
done | parallel -j4
```

… which is also equivalent to:

``` bash
ls -1 *_w_refs.FNA | \
parallel -j4  "echo {}; mafft --thread 2 --quiet --auto {} > aligned.{}"
```

In this step, MAFFT is run with an automatic selection of the alignment
algorithm (`--auto`). This can be changed according to your needs, for
more details, see the [MAFFT
documentation](https://mafft.cbrc.jp/alignment/software/algorithms/algorithms.html).
In the above commands, MAFFT is run on 2 threads (`--threads`). I would
not recommend using more threads to avoid over-threading. Also, be aware
of the number of threads requested when running in parallel (2 x 4 in
the above examples).

### Remove reference sequences

Now that our sequences are aligned, we need to remove the reference
sequences that we gathered, because we don’t want to reconstruct
phylogenetic trees with reference sequences in them.

For each locus name (i.e. locus name extracted from the
`aligned.<locus>_w_refs.FNA` file names): extract all the sequences that
DO NOT contain the locus name in their own sequence name, and append
these extracted sequences into a corresponding newly created
`aligned.<locus>.FNA file`.

``` bash
for locus in $(ls -1 aligned.*_w_refs.FNA | sed 's/_w_refs.FNA//g' | sed 's/aligned.//g')
do
  seqkit grep -w0 -v -nrp -$locus aligned.$locus_w_refs.FNA > aligned.$locus.FNA
done
```

… do the same in parallel:

``` bash
ls -1 aligned.*_w_refs.FNA | sed 's/_w_refs.FNA//g' | sed 's/aligned.//g' | \
parallel -j4 "echo {}; seqkit grep -w0 -v -nrp -{} aligned.{}_w_refs.FNA > aligned.{}.FNA"
```

Move the files that include the reference sequence in a separate
subdirectory.

``` bash
mkdir alignments_including_refs
mv aligned.*w_refs.FNA alignments_including_refs
rm *_w_refs.FNA
```

## Alignment trimming

After the sequence have been aligned, poorly aligned regions have to be
trimmed from multiple sequence alignments (MSAs).

Several programs exist to do so, such as
[ClipKIT](https://jlsteenwyk.com/ClipKIT/index.html),
[TrimAl](http://trimal.cgenomics.org/trimal) or
[Gblocks](https://home.cc.umanitoba.ca/~psgendb/doc/Castresana/Gblocks_documentation.html).
These programs usually trim the alignments based on the quality of the
alignment at a given position. Other approaches such as
[HmmCleaner](https://bioinformaticshome.com/tools/msa/descriptions/HmmCleaner.html)
remove poorly aligned regions on a sequence by sequence basis. Both
approaches can be combined.

Here I present alignment trimming with ClipKIT and TrimAl.

### Trimming using ClipKIT

Here we used the `smart-gap` mode, but this can be changed depending on
your needs (see details of the different modes in the [ClipKit
documentation](https://jlsteenwyk.com/ClipKIT/advanced/index.html)).

For each aligned file, trim using `clipkit`:

``` bash
for file in $(ls -1 aligned.*.FNA)
do
  clipkit $file -m smart-gap;
done
```

… same command running in parallel:

``` bash
ls -1 aligned.*.FNA | \
parallel -j4 "echo Trimming {}; clipkit {} -m smart-gap;"
```

Create a subdirectory, move the trimmed alignment in there and rename
the ClipKit-trimmed alignment to .FNA.

``` bash
mkdir clipkit
mv *clipkit clipkit
cd clipkit
rename -v '.FNA.clipkit' '.FNA' *
```

### Trimming using TrimAl

Here we used the `automated1` mode, but this can be changed depending on
your needs (see details of the different modes in the [TrimAl
documentation](http://trimal.cgenomics.org/getting_started_with_trimal_v1.2)).

For each aligned file, trim using `trimal`:

``` bash
for file in $(ls -1 aligned.*.FNA)
do
  trimal -in $file -out $file.trimal -automated1;
done
```

… same command running in parallel:

``` bash
ls -1 aligned.*.FNA | \
parallel -j$SLURM_NTASKS "echo Trimming {}; trimal -in {} -out {}.trimal -automated1;"
```

Create a subdirectory, move the trimmed alignment in there and rename
the TrimAl-trimmed alignment to .FNA.

``` bash
mkdir trimal
mv *.trimal trimal
cd trimal
rename -v '.FNA.trimal' '.FNA' *
```
