library(jsonlite)
library(dplyr)

# Read the rds file
df <- readRDS("../pfocr_figures_raw.rds")

# Read the jsonl file and extract the required information
json_data <- stream_in(file("predictions.jsonl"))
json_df <- as.data.frame(json_data$instance)
json_df$figid <- sub(".*/", "", json_df$content)
json_df$automl_type <- unlist(json_data$prediction$displayNames)
json_df$automl_score <- unlist(json_data$prediction$confidences)

# Remove the ".jpg" extension from the "id" column in the JSONL data frame
json_df$figid <- sub("\\.jpg$", "", json_df$figid)

# Convert "other" scores to "pathway" scores
json_df <- json_df %>%
  mutate(automl_pathway = if_else(automl_type=="other", 1-automl_score, automl_score))

# Merge the JSONL data with the original data frame based on the id column
df <- merge(df, json_df[c("figid", "automl_pathway")], by = "figid", all.x = TRUE)

# Produce count log
line1 <- sprintf("Number of figures: %d", nrow(df))
line2 <- sprintf("Number of predicted pathways: %d", sum(df$automl_pathway >= 0.5))
file_path <- "automl_counts.txt"
cat(line1, "\n",line2, "\n", file = file_path)

# Save the updated data frame as an rds file
saveRDS(df, "../pfocr_figures_automl.rds")

# Move "other" images and metadata to subfolders
subfolder1 <- "../1_images/other"
if (!dir.exists(subfolder1)) {
  dir.create(subfolder1)
}
subfolder2 <- "../1_metadata/other"
if (!dir.exists(subfolder2)) {
  dir.create(subfolder2)
}

for (i in 1:nrow(df)) {
  figid <- df$figid[i]
  automl_pathway <- df$automl_pathway[i]
  
  if (automl_pathway < 0.5) {
    source_path1 <- file.path("../1_images", paste0(figid, ".jpg"))
    dest_path1 <- file.path(subfolder1, paste0(figid, ".jpg"))
    file.rename(source_path1, dest_path1)
    source_path2 <- file.path("../1_metadata", paste0(figid, ".yml"))
    dest_path2 <- file.path(subfolder2, paste0(figid, ".yml"))
    file.rename(source_path2, dest_path2)
  }
}

