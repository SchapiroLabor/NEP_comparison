# install packages

# Install packages
library(FactoMineR)
library(ggcorrplot)
library(corrr)
library(readr)
library(ggfortify)
library(ggplot2)
library(randomForestSRC)
library(caret)
library(tidyverse)

# load in data

csv_dir = "./../../results_4ct_sym/"
data <- list.files(path = csv_dir, recursive = FALSE, pattern = "\\.csv$")
all = list()
for (i in 1:length(data)){
  all[[i]] <- as.data.frame(read_csv(paste0(csv_dir,data[i])))
  #rownames(all[[i]]) = sub("4ct_self", "", as.vector(all[[i]][,1]))
  rownames(all[[i]]) = as.vector(all[[i]][,1])
  rownames(all[[i]]) = sub(".csv", "", rownames(all[[i]]))
  all[[i]] = all[[i]][,-1]
  
  
  # switch interactions colnames Misty
  colnames(all[[i]]) = sub("(.*)_(.*)", "\\2_\\1", colnames(all[[i]]))}

#switch back for histoCAT
for(i in grep("histo", data)){
  colnames(all[[i]]) = sub("(.*)_(.*)", "\\2_\\1", colnames(all[[i]]))
}


# more features for Giotto

giotto_inidces <- which(sapply(all, function(df) ncol(df) == 10))

for (i in giotto_inidces){
  dob = all[[i]][, !colnames(all[[i]]) %in% c("0_0", "1_1", "2_2", "3_3")]
  colnames(dob) = sub("(.*)_(.*)", "\\2_\\1", colnames(dob))
  all[[i]] = cbind(all[[i]] , dob)
}


##make all datasets the same order and without any numbers in the feature names
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
  # Reorder rows of dataset1 using the ordered row names
  all[[i]] <- all[[i]][, ordered_cols , drop = FALSE]
}

#look at correct names
for (i in 1:length(all)){
  print(colnames(all[[i]]))
}


### create defining group columns

df_list = list()

for (i in 1:length(all)){
  #all[[i]]$preference <- sub("_ab.*sim_\\d+$", "", rownames(all[[i]]))
  #all[[i]]$preference <- sub("self_", "self0_", all[[i]]$preference)
  all[[i]]$preference <- sub("_ab.*$", "", rownames(all[[i]]))
  all[[i]]$preference <- sub("_ab.*$", "", all[[i]]$preference)
  all[[i]]$abundance <- sub(".*ab", "ab", rownames(all[[i]]))
  all[[i]]$abundance = sub("_[0-9]+$", "", all[[i]]$abundance)
  all[[i]]$abundance = sub("_sim", "", all[[i]]$abundance)
}


### make naming convention

df_comb = list()
split_string <- strsplit(data, "4ct")
#toollist <- sub("_+$", "", split_string[[1]][1])
#part_after_sim <- paste("sim", split_string[[1]][2], sep = "")

# now loop through every combination of abundances are preferences to compare all tools withtin their abundances
for (i in 1:length(all)){
  combs <- combn(unique(all[[i]]$preference), 2)
  pref_comb <- apply(combs, 2, function(x) c(as.character(x[1]), as.character(x[2])))
  for (a in unique(all[[i]]$abundance)){
    df = all[[i]] %>% filter(abundance == a)
    for (p in 1:ncol(pref_comb)){
      df2 = df %>% filter(preference %in% pref_comb[,p]) 
      df_comb[[paste(sub("_+$", "", split_string[[i]][1]), unique(df2$abundance), unique(df2$preference)[1], "vs", unique(df2$preference)[2], sep = "_")]] = df2 %>% select(-preference, -abundance)
      #df_comb[[paste(sub("_+$", "", split_string[[i]][1]), unique(df2$abundance), paste(pref_comb[,p], sep = "_vs_"), sep = "_")]] = df2
    }
  }
}

# these are the comparisons we have:
names = names(df_comb)

names(df_comb)

all = df_comb

### extract weak vs strong comparison wfor interaction 0-1
#for (i in grep("0.25_cross01_0.45_vs_cross01_0.6", names)){
for (i in grep("0.25_self_0.45_vs_self_0.6", names)){
  groups = rep(unlist(strsplit(names(all[i]), "_vs_")), each = 100)
  data = as.data.frame(cbind(rownames(all[[i]]), as.numeric(all[[i]][,1]), groups))
  data$V2 = as.numeric(data$V2)
  legend = rep(c("strong", "weak"), each = 100)
  
  plot_histo = ggplot(data, aes(x = V2, fill = legend)) +
          geom_histogram (bins = 50) +
          facet_grid(. ~ groups) +
          labs(title = names(all)[i], x = "interaction_value", y = "Frequency") +
          theme_classic() +
          scale_fill_manual(values = c("darkred", "darkblue"))
          
        
  ggsave(filename = paste0("./../../results_4ct_sym/interaction_distributions/", names[i], ".svg"), plot = plot_histo, width = 4, height = 2.5)
          
}









