#!/usr/bin/env bash

# chmod +x train_step_2.sh

# When the training is done, the result will be stored in the bucket.
# Download the csv.
gsutil -m cp \
  -r gs://[Bucket Name]/ \
  .

# We can easily concat these jsonl files to a single jsonl file and then run process_raw_rds.R to process the data.
# Then we can delete all data in the bucket:

gsutil -m rm -r gs://[Bucket Name]/*
