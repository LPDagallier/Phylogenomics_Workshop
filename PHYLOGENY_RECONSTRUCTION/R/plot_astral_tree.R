##############################################################################
# Description: Plot phylogenetic trees from ASTRAL output
# Input:
# - tree_file: file name of the tree (output from ASTRAL)
# - rename (logical, default = F): whether to rename the tips or not, needs tiplabels to be specified
# - tiplabels: data-frame with 1 columns "OLD" containing the old tip labels to be renamed, and 1 column "NEW" containing the new tiplabels
# - annotations: which annotation to output; LPP = Local Posterior Probabilities, QS = Quartet Scores (default is both LPP, QS and none). Providing different values will output different .pdf files.
# - bl: whether displaying branch length (bl = "branch.length", the default) or whether displaying equal branch length, i.e. a cladogram (bl = "none")
# - output file name (default is tree_file.pdf)
# Output:
# - .pdf files containing plot of the tree with quartet support (QS) in one file and local posterior probabilities (LPP) in another file
# IMPORTANT:
# - tree is expected to be annotated with the `-t 2` option in ASTRAL
#
# Author: Leo-Paul Dagallier
# Date Created: 2022-11-29
##############################################################################

# Packages -------------------------------------------------------------------
library(treeio)
library(ggplot2)
library(ggtree)

# Main code ------------------------------------------------------------------
plot_astral <-  function(tree_file, rename = F, tiplabels = NULL, annotations = c("LPP", "QS", "none"), bl = "branch.length", legend_position = c(0.2, 0.1), legend_size = 1, out_filename = NULL){
  tree <- treeio::read.astral(tree_file)
  if (rename == T && !is.null(tiplabels)){
    # tiplabels$OLD %in% tree@phylo$tip.label
    tiplabels <- tiplabels[tiplabels$OLD %in% tree@phylo$tip.label,]
    tree <- rename_taxa(tree, tiplabels, key = OLD, value = NEW)
    }
  
  # PREPARE OUTPUT
  if (is.null(out_filename)){out_filename = tree_file}
  ggsave_custom <- function(plot, suffix){ggsave(plot, filename = paste0(out_filename, suffix, ".pdf"), scale = 1, width = 20*ntips, height = 20*ntips, units = "px", dpi = 300, limitsize = F)}
  
  # PREPARE PLOTTING PARAMETERS:
  root <- rootnode(tree)
  tiplab_size = 2
  p <- ggtree(tree, color="black", size=.5, linetype=1, right=TRUE, branch.length=bl)
  xrange <- ggplot_build(p)$layout[["panel_params"]][[1]][["x.range"]]
  ntips <- length(tree@phylo$tip.label)
  
  # PREPARE BASIC TREE
  basic_plot <- ggtree(tree, color="black", size=.5, linetype=1, right=TRUE, branch.length=bl) +
    geom_tiplab(size = tiplab_size)+
    coord_cartesian(xlim = c(0, xrange[2] + 0.1*diff(xrange)), ylim = c(0, ntips))
  
  # PLOT BASIC TREE (NO ANNOTATION)
  if("none" %in% annotations){
    ggsave_custom(basic_plot, suffix = "")
  }
  
  # PLOT WITH LPP AT BRANCHES
  if ("LPP" %in% annotations) {
  LPP_plot <- basic_plot +
    geom_point2(aes(x = branch, y = y, subset=!isTip & node != root, fill=cut(pp1, c(0, 0.7, 0.9, 1))), shape=21, size=2.2, stroke = 0.3)+
    theme_tree(legend.position=legend_position, legend.key.size = unit(legend_size, "pt")) +
    scale_fill_manual(values=c("black", "grey", "white"), guide='legend',
                      name='Local Posterior Probability (LPP)',
                      breaks=c('(0.9,1]', '(0.7,0.9]', '(0,0.7]'),
                      labels=expression(LPP>=0.9,0.7 <= LPP * " < 0.9", LPP < 0.7))
  # ggsave(LPP_plot, filename = paste0(out_filename,"_PP.pdf"), scale = 1, width = 20*ntips, height = 20*ntips, units = "px", dpi = 300, limitsize = F)
  ggsave_custom(LPP_plot, suffix = "_PP")
  }
  
  # PLOT WITH QUARTET SUPPORT AT BRANCHES
  if ("QS" %in% annotations){
  quartet_cols = c(which(colnames(tree@data) == "q1"), which(colnames(tree@data) == "q2"), which(colnames(tree@data) == "q3"))
  pies=nodepie(tree@data, cols = quartet_cols, color = c("black", "#bdbdbd", "#f0f0f0"), outline.color = "black")
  # pies[[15]]
  # QS <- tree@data[,c(13,9:11)] %>% pivot_longer(cols= 2:4, names_to = "QS", values_to = "value")
  # pies <- lapply(X = unique(QS$node), FUN = function(x){
  #   QS %>% tidytree::filter(node == x) %>% ggpubr::ggpie(x = "value", label = c("","",""), fill = "QS", color = c("black"), size = .2, palette = c("black", "#bdbdbd", "#f0f0f0"), legend = 'none', lab.pos = 'in', lab.font = "transparent", ggtheme = theme_void())
  # })
  names(pies) <- unique(tree@data$node)
  pie_diam = 3/ ntips
  # pie_diam = 0.02
  QS_plot <- basic_plot +
    geom_inset(insets <- pies, x = "branch", width = pie_diam, height = pie_diam, hjust = 10/ntips, vjust = 50/ntips)
  # ggsave(QS_plot, filename = paste0(out_filename,"_QS.pdf"), scale = 1, width = 20*ntips, height = 20*ntips, units = "px", dpi = 300, limitsize = F)
  ggsave_custom(QS_plot, suffix = "_QS")
  }
}

# End of script
##############################################################################