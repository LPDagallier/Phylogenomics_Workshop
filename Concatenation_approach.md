Concatenation Approach
================

**Author**: [Léo-Paul Dagallier](https://github.com/LPDagallier)  
**Last update**: 2023-10-18

------------------------------------------------------------------------

In the concatenation approach we will first concatenate the MSAs of all
the loci into a single MSA (or ‘supermatrix’), and then infer the
species tree from the supermatrix.

Here we’ll present species tree inference with
[RAxML](https://cme.h-its.org/exelixis/web/software/raxml/) and
[IQ-TREE](http://www.iqtree.org/). With RAxML, the MSAs for all the loci
need to be concatenated into a single supermatrix prior to RAxML
inference. With IQ-TREE, we can directly input all the MSAs files that
will be concatenated internally by IQ-TREE.

## Infer tree with IQ-TREE
