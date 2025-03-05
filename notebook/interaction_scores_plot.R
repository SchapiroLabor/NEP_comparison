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
csv_dir = "./../../20250218_results_sym/"
data <- list.files(path = csv_dir, recursive = FALSE, pattern = "\\.csv$")
output_folder = "./../../../../Paper_figures/condzscore_v3/interaction_scores/"

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

for (i in 1:length(all)){
  all[[i]]$preference <- sub("_ab.*$", "", rownames(all[[i]]))
  all[[i]]$preference <- sub("_ab.*$", "", all[[i]]$preference)
  all[[i]]$abundance <- sub(".*ab", "ab", rownames(all[[i]]))
  all[[i]]$abundance = sub("_[0-9]+$", "", all[[i]]$abundance)
  all[[i]]$abundance = sub("_sim", "", all[[i]]$abundance)
}

# prepare lists
df_comb = list()
split_string <- strsplit(data, "4ct")

for (i in 1:length(all)){
  
  combs <- combn(unique(all[[i]]$preference), 2)
  pref_comb <- apply(combs, 2, function(x) c(as.character(x[1]), as.character(x[2])))
  for (a in unique(all[[i]]$abundance)){
    df = all[[i]] %>% filter(abundance == a)
    for (p in 1:ncol(pref_comb)){
      df2 = df %>% filter(preference %in% pref_comb[,p]) 
      df_comb[[paste(sub("_+$", "", split_string[[i]][1]), unique(df2$abundance), unique(df2$preference)[1], "vs", unique(df2$preference)[2], sep = "_")]] = df2 %>% select(-preference, -abundance)
    }
  }
}
names = names(df_comb)
all = df_comb

### PLOTTING

# extract weak vs strong comparison for NEP 0-1 and 1-0 at abundance 25%
for (i in grep("0.25_self00_0.45_vs_self00_0.6|0.25_self00_0.6_vs_self00_0.45", names)){
  groups = rep(unlist(strsplit(names(all[i]), "_vs_")), each = 100)
  data = as.data.frame(cbind(rownames(all[[i]]), as.numeric(all[[i]][,1]), groups))
  data$V2 = as.numeric(data$V2)
  legend = rep(c("weak", "strong"), each = 100)
  
  plot_histo = ggplot(data, aes(x = V2, fill = legend)) +
          geom_histogram (bins = 50) +
          facet_grid(. ~ groups) +
          labs(title = names(all)[i], x = "interaction_value", y = "Frequency") +
          theme_classic() +
          scale_fill_manual(values = c("darkred", "darkblue"))
          
        
  ggsave(filename = paste0(output_folder, names[i], ".svg"), plot = plot_histo, width = 4, height = 1.5)
          
}