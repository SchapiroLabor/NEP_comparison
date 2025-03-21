#################################################
### Script for plotting NEP distributions     ###
### Schiller et at. 2025.                     ###
### Author: Chiara Schiller                   ###
#################################################

### This script loads the NEP method .csv results and plots the NEP score distributions for Figure 2c

# Load packages
library(FactoMineR)
library(ggcorrplot)
library(corrr)
library(readr)
library(ggfortify)
library(ggplot2)
library(randomForestSRC)
library(caret)
library(tidyverse)

### DATA PATHS
csv_dir = "./../../../Comparison/20250218_results_sym/"
data <- list.files(path = csv_dir, recursive = FALSE, pattern = "\\.csv$")
output_folder = "./../../../../Paper_figures/condzscore_v3/interaction_scores_wcellcharter/"

### DATA WRANGLING
all = list()
for (i in 1:length(data)){
  print(i)
  all[[i]] <- as.data.frame(read_csv(paste0(csv_dir,data[i])))
  rownames(all[[i]]) = as.vector(all[[i]][,1])
  rownames(all[[i]]) = sub(".csv", "", rownames(all[[i]]))
  all[[i]] = all[[i]][,-1]
  all[[i]] = all[[i]][!grepl("count_", rownames(all[[i]])), ]
  all[[i]] = all[[i]][rownames(all[[1]]), ]
  colnames(all[[i]]) = gsub("\\.0", "", colnames(all[[i]]))
  colnames(all[[i]]) = gsub("X", "", colnames(all[[i]]))
}

# Make all datasets the same order and without any numbers in the feature names
modify_row_names <- function(row_name) {
  numbers <- gsub("\\D", "", row_name)
  modified_name <- paste(strsplit(numbers, "")[[1]], collapse = "_")
  return(modified_name)
}

for (i in 1:length(all)){
  colnames(all[[i]]) <- as.vector(sapply(colnames(all[[i]]), modify_row_names))
}

# correct order for ground truth later 
ordered_cols <- c("0_0", "0_1", "0_2", "0_3", "1_0", "1_1", "1_2", "1_3", "2_0", "2_1", "2_2", "2_3", "3_0", "3_1", "3_2", "3_3")
# Combine the results into the stat list
for (i in 1:length(all)) {
  if (ncol(all[[i]]) == 16) {
    # Reorder rows of dataset1 using the ordered row names
    all[[i]] <- all[[i]][, ordered_cols , drop = FALSE]
    # Drop the row where the name is 'new_column'
    all[[i]] <- all[[i]][1:2400,]
    all[[i]] <- all[[i]][complete.cases(all[[i]]), ]
    all[[i]] <- all[[i]] %>% mutate_all(as.numeric)
    all[[i]] <- all[[i]][match(rownames(all[[1]]), rownames(all[[i]])), ]
    all[[i]] <- all[[i]][order(rownames(all[[i]])), ]
  }
}

df_list = list()
all[[i]]
for (i in 1:length(all)){
  all[[i]] <- all[[i]] %>%
    rownames_to_column(var = "Sample") %>%
    pivot_longer(cols = -Sample, names_to = "Interaction", values_to = "Value")
  
  all[[i]]$preference <- sub("_ab.*$", "", all[[i]]$Sample)
  all[[i]]$preference <- sub("_ab.*$", "", all[[i]]$preference)
  all[[i]]$abundance <- sub(".*ab", "ab", all[[i]]$Sample)
  all[[i]]$abundance = sub("_[0-9]+$", "", all[[i]]$abundance)
  all[[i]]$abundance = sub("_sim", "", all[[i]]$abundance)
}

names(all) = data

### PLOTTING
plots <- list()  # Store individual plots
names(all) = c("CellCharter", "COZI", "ct_abundances", "Giotto", "histoCAT", "IMCRclassic_not", "hist_not", "IMCRtools", "Misty", "Scimap", "SEA", "Interaction count", "Squidpy")
include= c("CellCharter", "COZI", "Giotto", "histoCAT", "IMCRtools", "Misty", "Scimap", "SEA", "Interaction count", "Squidpy")

all = all[names(all) %in% include]

# Extract weak vs strong comparison for NEP 0-1 and 1-0 at abundance 25%
for (i in 1:length(all)) {
    print(i)
    
  data <- as.data.frame(all[[i]]) %>%
    filter(preference %in% c("self00_0.45", "self00_0.6", "ran")) %>%
    select(Value, preference) %>%
    mutate(preference = factor(preference, 
                               levels = c("ran", "self00_0.45", "self00_0.6"), 
                               labels = c("random", "weak", "strong")))
  
  colnames(data) <- c("interaction", "preference")
  
  plot_histo <- ggplot(data, aes(x = interaction, fill = preference)) +
    geom_histogram(bins = 50) +
    facet_grid(. ~ preference) +
    labs(title = names(all)[i], x = "NEP score", y = "Frequency") +
    theme_classic() +
    scale_fill_manual(values = c("darkgreen","darkred", "darkblue")) +
    theme(legend.position = "none") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  plots[[i]] <- plot_histo 
  }


combined_plot = grid.arrange(grobs = plots, ncol = 2) 
# Combine all plots into one figure
# Save combined plot
ggsave(filename = paste0(output_folder, "Overall_Plots.svg"), plot = combined_plot, width = 7, height = 9)


