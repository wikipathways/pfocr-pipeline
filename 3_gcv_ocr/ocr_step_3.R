library(dplyr)

# Read the rds file
df <- readRDS("../pfocr_figures_automl.rds")

# Retrieve the figids of figures with OCR results
ocr_figids <- list.files(".", pattern = "\\.json$", full.names = FALSE) 
ocr_figids <- sub("\\.json", "",ocr_figids)

# Subset df to only include figures with OCR results
df <- df %>%
  dplyr::filter(automl_pathway >= 0.5) %>%
  dplyr::filter(figid %in% ocr_figids)

# Save the updated data frame as an rds file
saveRDS(df, "../pfocr_figures_ocr.rds")

# Produce count log
line1 <- sprintf("Number of figures with OCR results: %d", nrow(df))
log_path <- "ocr_counts.txt"
cat(line1, "\n", file = log_path)
