# load libraries
library(FactoMineR)
library(ggcorrplot)
library(corrr)
library(readr)
library(ggfortify)
library(ggplot2)
library(randomForestSRC)
library(caret)
library(tidyverse)
library(factoextra)
library(pheatmap)


# modify rownames of datasets to not contain numbers
modify_row_names <- function(row_name) {
  numbers <- gsub("\\D", "", row_name)
  modified_name <- paste(strsplit(numbers, "")[[1]], collapse = "_")
  return(modified_name)
}


# create heatmaps for datasets
heatmaps <- function(data, df_name){
  pheatmap(data, treeheight_row = 0, treeheight_col = 0, main = df_name, cluster_rows = F)
}
