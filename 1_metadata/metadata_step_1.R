# Prune and transform folder of PFOCR yaml files into an pfocr_figures.rds
library(yaml)
library(dplyr)


yml.dir <- "."
img.dir <- "../1_images"

##############
# PRUNE YML #
############
# First, filter yml files for those with corresponding jpg image files. Stash
# the unmatched yml files in a subdir

dir.create(file.path(yml.dir,"no_image"), showWarnings = F)

for (yml_file in list.files(yml.dir, pattern = "\\.yml$", full.names = TRUE)) {
  yml_filename <- basename(yml_file)
  # Check if there is a matching .jpg file
  if (!file.exists(file.path(img.dir, gsub("\\.yml$", ".jpg", yml_filename)))) {
    file.rename(yml_file, file.path(yml.dir,"no_image", yml_filename))
  }
}

#############
# MAKE RDS #
###########
# Transforme ymls into an rds. Concatenate "keywords" separated by " | "

yml_files <- list.files(yml.dir, pattern = "\\.yml$", full.names = TRUE)

# Define a function to read a single .yml file and convert it to a data frame
read_yml_file <- function(file_path) {
  # Read the .yml file and convert to a named list
  yml_data <- yaml::read_yaml(file_path)
  # Convert the named list to a data frame with one row
  df <- dplyr::tibble(
    figid = yml_data$figid,
    pmcid = yml_data$pmcid,
    filename = yml_data$image_filename,
    figlink = yml_data$figure_link,
    number = yml_data$number,
    figtitle = yml_data$figure_title,
    caption = yml_data$caption,
    papertitle = yml_data$article_title,
    reftext = yml_data$citation,
    year = yml_data$year,
    doi = yml_data$doi,
    journal_title = yml_data$journal_title,
    journal_nlm_ta = yml_data$journal_nlm_ta,
    publisher_name = yml_data$publisher_name,
    keywords = paste(yml_data$keywords, collapse = " | ")
  )
  return(df)
}

# Loop through each .yml file, read it and combine the data into a single data frame
df <- dplyr::bind_rows(lapply(yml_files, read_yml_file)) %>% as.data.frame()

saveRDS(df, "../pfocr_figures_raw.rds")
