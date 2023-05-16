library(jsonlite)
library(dplyr)

# Read the rds file
df <- readRDS("pfocr_figures_raw.rds")

# Read the jsonl file and extract the required information
json_data <- stream_in(file("predictions.jsonl"))
json_df <- as.data.frame(json_data$instance)
json_df$figid <- sub(".*/", "", json_df$content)
json_df$automl_type <- json_data$prediction$displayNames
json_df$automl_score <- json_data$prediction$confidences


# Remove the ".jpg" extension from the "id" column in the JSONL data frame
json_df$figid <- sub("\\.jpg$", "", json_df$figid)

# Merge the JSONL data with the original data frame based on the id column
df <- merge(df, json_df[c("figid", "automl_type")], by = "figid", all.x = TRUE)
df <- merge(df, json_df[c("figid", "automl_score")], by = "figid", all.x = TRUE)

df$automl_score <- ifelse(df$automl_type == "other", -1, df$automl_score)

# Save the updated data frame as an rds file
saveRDS(df, "pfocr_figures_processed.rds")
