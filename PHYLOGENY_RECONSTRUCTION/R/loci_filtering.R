##############################################################################
# Description: Script to filter the loci based on their percentage of length recovered
#              and on the percentage of samples in which they were recovered
# Input:
# - genes_sequences_lengths_raw: a data frame with loci sequences length per sample, as output by HybPiper (genes_sequences_lengths.tsv)
# - limit_perc_length_wanted: a numeric vector with all the L values desired
# - limit_perc_nb_wanted: a numeric vector with all the N values desired
# limit_perc_length_wanted and limit_perc_nb_wanted have to be the same length. L_N subsets are defined by the combination of both values at a position in the vectors, so values have to be ordered according to the L_N subset you want to define (1st values are assembled together, and so on).

# Output:
# - a text file for every L_N subset defined with the list of loci in the subset (`list_L_N.txt`)
# - a text file for every L_N subset defined with the bash copy command of loci in the subset (`move_L_N.txt`)
# - a table summarizing the number of loci recovered for the different L and N values (`exon_filtering_stats.csv`)
# - a gradient plot (heatmap) representing the number of loci recovered for each percentage of samples and percentage of length assembled (`exon_recovery_gradient_samples.png`)
# - additional density plots of the exons length recovery (`L_N_exon_length_density.png`)
#
# Author initial version: Andrew Helmstetter (https://github.com/ajhelmstetter/afrodyn)
# Modification, maintenance and updates: Leo-Paul Dagallier (https://github.com/LPDagallier)
# Citation example: "We filtered the loci on their assembly length and sample recovery (e.g. Couvreur et al 2019 (https://doi.org/10.3389/fpls.2018.01941), Dagallier et al. 2023 (https://doi.org/10.1093/aob/mcad130))"

# Date of last update: 2023-10-09
##############################################################################


# Load the necessary packages ---------------------------------------------
library(ggpubr)
library(tidyverse)
library(reshape2)
library(wesanderson)

# Set the paths and load the data -----------------------------------------
# PATH SETTING AND DATA LOADING SHOULD BE DONE PRIOR TO CALL THIS SCRIPT WITH SOURCE
# THIS SHOULD BE DONE FOLLOWING THE COMMENTED EXAMPLE BELOW
# path_to_data <- "C:/Users/ldagallier/Documents/RESEARCH/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/JOBS_OUTPUTS/hybpiper2_FMN_104811_P005_005_44549545"
# filename = paste0(path_to_data, "/genes_sequences_lengths.tsv")
# genes_sequences_lengths_raw <- read.table(filename, header = T, row.names = 1, sep = "\t", check.names = F)
# path_to_out <- "C:/Users/ldagallier/Documents/RESEARCH/DATA_ANALYSES/PHYLOGENY_RECONSTRUCTION/DATA/FMN_104811_P005_005/"
# limit_perc_length_wanted = c(0.1, 0.5, 0.75)
# limit_perc_nb_wanted = c(0.1, 0.5, 0.75)
# 

# Prepare the data frames -------------------------------------------------
# FIRST: sort the locus names in the raw data frame
genes_sequences_lengths_raw <- genes_sequences_lengths_raw[,order(names(genes_sequences_lengths_raw))]
# get the length of reference sequence for each locus
reference_length = as.numeric(genes_sequences_lengths_raw[which(row.names(genes_sequences_lengths_raw)== "MeanLength"),])
names(reference_length) <- names(genes_sequences_lengths_raw)

# Keep the sequences lengths only for the genes (that is: remove MeaLength from the dataframe)
sequence_lengths = genes_sequences_lengths_raw[which(row.names(genes_sequences_lengths_raw) != "MeanLength"),]

# Table of the number of samples per locus --------------------------------
sequence_PA = ifelse(sequence_lengths > 0, 1, 0) # draw a presence/absence table
tmp <- colSums(sequence_PA)
samples_per_locus <- data.frame(locus = names(tmp), n_samples = tmp, check.names = F, row.names = NULL)
write.csv(samples_per_locus, paste0(path_to_out, "samples_per_locus.csv"))

# Calculate percentage of length recovered for each exon in each sample --------
percent_length = sweep(sequence_lengths, 2, reference_length, "/")
percent_length <- apply(percent_length, c(1,2), FUN = function(x) ifelse(x>1,1,x)) # checks no value is above 1

# Prepare matrix for heatmap ----------------------------------------------
#set thresholds
limits <- seq(0.01, 0.99, 0.01)

#make empty matrix
loci_stats <- matrix(nrow = length(limits), ncol = length(limits))

# loop through threshold combinations
pb <- txtProgressBar(min = 0, max = length(limits), style = 3, width = 100, char = "=")  
for (i in 1:length(limits)) {
  for (j in 1:length(limits)) {
    
    #reset limits
    percent_len_limit <- percent_length
    
    # if percentage exon length recovered is >= limit make value 1
    # if not make value 0
    percent_len_limit[which(percent_len_limit >= limits[i])] <-  1
    percent_len_limit[which(percent_len_limit < limits[i])] <-  0
    
    # For each locus calculate number of samples with >= limit
    col <- colSums(percent_len_limit != 0)
    
    # Calculate % samples with >= limits of exon for each exon
    col <- col/nrow(percent_length)
    
    loci_stats[i, j] <-  table(col >= limits[j])["TRUE"]
    
    setTxtProgressBar(pb, i)
    # print(paste(i, "% of exon length in ", j, " % of samples", sep=""))
    }
}
close(pb)

# Gradient plot (heatmap) -------------------------------------------------
loci_stats <- data.frame(loci_stats)

for (i in 1:length(limits)) {
  colnames(loci_stats)[i] <-  limits[i] * 100
  loci_stats$percent_of_locus_length[i] <-  limits[i] * 100
}

#melt table
loci_stats_melt <- melt(loci_stats, id.vars = "percent_of_locus_length")
# head(loci_stats_melt)
loci_stats_melt$variable <- as.numeric(loci_stats_melt$variable)
colnames(loci_stats_melt) <- c("percent_of_locus_length", "percent_of_samples", "n_loci")
loci_stats_melt$display_val <- NA

limits_wanted_pairs <- cbind(limit_perc_length_wanted,limit_perc_nb_wanted)
to_display <- apply(limits_wanted_pairs, 1, FUN = function(x){
  which(loci_stats_melt$percent_of_locus_length == (x[1]*100) & loci_stats_melt$percent_of_samples == (x[2]*100))})
loci_stats_melt$display_val[to_display] <- TRUE
# loci_stats_melt$display_val[-to_display] <- FALSE

# Gradient color
xbreaks <- sort(unique(c(25,50,75,limit_perc_length_wanted*100)))
ybreaks <- sort(unique(c(25,50,75,limit_perc_nb_wanted*100)))

pal <- wes_palette("Zissou1", 100, type = "continuous")
p <- ggplot(loci_stats_melt, aes(percent_of_locus_length, percent_of_samples, z = n_loci))
p + geom_raster(aes(fill = n_loci)) +
  scale_fill_gradientn(colours = pal, name = "No. exons", breaks = scales::breaks_extended(n = 10)) +
  guides(fill = guide_colourbar(barheight = 20))+
  scale_y_continuous(expand = c(0, 0), breaks = xbreaks) +
  scale_x_continuous(expand = c(0, 0), breaks = ybreaks) +
  labs(y= "% samples with exon", x = "% exon length recovered", caption = paste0("Max. ", max(loci_stats_melt$n_loci, na.rm = T), " exons were recovered (over the ", length(reference_length), " in the target sequences set).")) +
  geom_contour(colour = "white", linetype = "dashed", alpha = 0.5, breaks = scales::breaks_extended(n = 10)) +
  geom_point(data = ~filter(.x, display_val == T), color = "grey40", show.legend = T)+
  geom_text(data = ~filter(.x, display_val == T), aes(label = n_loci), hjust =-0.5, color = "grey40", show.legend = T)+
  theme(
    text = element_text(size = 10),
    axis.text = element_text(size = 10),
    axis.title.x = element_text(size = 11, margin = margin(
      t = 5,
      r = 0,
      b = 0,
      l = 0
    )),
    legend.title = element_text(),
    legend.text = element_text(size = 10),
    panel.border = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    panel.background = element_blank()
  )

ggsave(paste0(path_to_out, "exon_recovery_gradient_samples.png"), width = 8, height = 8)


# Save number of locus recovered in a table -------------------------------

#set thresholds
limits <- c(0,0.01, 0.1, 0.25, 0.5, 0.75, 0.9,0.99, 1)

#make empty matrix
loci_stats <- matrix(nrow = length(limits), ncol = length(limits))

#loop through threshold combinations
# = same loop as above
for (i in 1:length(limits)) {
  for (j in 1:length(limits)) {
    percent_len_limit <- percent_length
    percent_len_limit[which(percent_len_limit >= limits[i])] <-  1
    percent_len_limit[which(percent_len_limit < limits[i])] <-  0
    col <- colSums(percent_len_limit != 0)
    col <- col/nrow(percent_length)
    loci_stats[i, j] <-  table(col >= limits[j])["TRUE"]
  }
}

#make table presentable
colnames(loci_stats) <- paste0(limits*100, "% samples")
rownames(loci_stats) <- paste0(limits*100, "% exons")
loci_stats[is.na(loci_stats)] <- 0
write.csv(loci_stats, paste0(path_to_out, "exon_filtering_stats.csv"))


# Filter the list of loci according to desired percentage -----------------
# NEEDS TO DEFINE THE VALUES OF limit_perc_length_wanted AND limit_perc_nb_wanted BEFOREHAND
# NEEDS TO HAVE limit_perc_length_wanted AND limit_perc_nb_wanted TO BE THE SAME LENGTH
# otherwise default will be set 0.75 for both
if (! "limit_perc_length_wanted" %in% ls() || length(limit_perc_length_wanted) != length(limit_perc_nb_wanted)) limit_perc_length_wanted <- 0.75
if (! "limit_perc_nb_wanted" %in% ls() || length(limit_perc_length_wanted) != length(limit_perc_nb_wanted)) limit_perc_nb_wanted <- 0.75

for (i in 1:length(limit_perc_length_wanted)){
  # if percentage exon length recovered is >= limit_perc_length_wanted make value 1
  # if not make value 0
  percent_len_limit <- percent_length
  percent_len_limit[which(percent_len_limit >= limit_perc_length_wanted[i])] = 1
  percent_len_limit[which(percent_len_limit < limit_perc_length_wanted[i])] = 0
  
  # For each exon, calculate number of samples in which the exon is recovered with a length >= limit_perc_length_wanted
  col <- colSums(percent_len_limit)
  
  # From this number, calculate the % of samples (in which the exon is recovered with a length >= limit_perc_length_wanted)
  col <- col/(nrow(sequence_lengths)) # percentage 
  # table(col >= limit_perc_nb_wanted[i])
  
  # Retrieve the list of exons that are recovered with a length greater than limit_perc_length_wanted in more than limit_perc_nb_wanted samples
  filtered_exons <- names(which(col >= limit_perc_nb_wanted[i]))
  
  # Filter the original dataset (exon length) to keep only the filtered exons
  length_wanted <- sequence_lengths[, filtered_exons]
  
  # Density plot of filtered exon lengths -----------------------------------
  #Density plot of exon lengths with rug of actual exon lengths
  #make data frame
  marker_len <- data.frame(filtered_exons, as.numeric(reference_length[filtered_exons]))
  colnames(marker_len) <- c("locus", "length")
  
  # Basic density plot with mean line and marginal rug
  ggdensity(
    marker_len,
    x = "length",
    fill = "#0073C2FF",
    color = "#0073C2FF",
    alpha = 0.15,
    add = "mean",
    rug = TRUE,
    xlab = "Recovered exon length (bp)",
    ylab = "Density",
    title = paste0(100*limit_perc_length_wanted[i],"_",100*limit_perc_nb_wanted[i], " filter"),
    xlim = c(0, max(reference_length))
  )
  
  ggsave(paste0(path_to_out, (100*limit_perc_length_wanted[i]), "_", (100*limit_perc_nb_wanted[i]), "_exon_length_density.png"))
  
  
  # Create copy commands for keep filtered loci - for use downstream --------
  cat(
    x = paste0("cp *", filtered_exons, "*.FNA ", (100*limit_perc_length_wanted[i]), "_", (100*limit_perc_nb_wanted[i]),"/"),
    file = paste0(path_to_out, "move_", (100*limit_perc_length_wanted[i]), "_", (100*limit_perc_nb_wanted[i]), ".txt"),
    sep = "\n"
  )
  
  # Create list of filtered loci - for use downstream --------
  cat(
    x = sort(paste0(filtered_exons)),
    file = paste0(path_to_out, "list_", (100*limit_perc_length_wanted[i]), "_", (100*limit_perc_nb_wanted[i]), ".txt"),
    sep = "\n"
  )
}

