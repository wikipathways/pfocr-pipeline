#!/usr/bin/env bash

# chmod +x predict_step_2.sh

# When the prediction is done, the result will be stored in the bucket.
# Download all jsonl files from predictions_00001.jsonl to predcitions_00010 to your machine.
gsutil -m cp \
  "gs://[Bucket Name]/predictions_00001.jsonl" \
  "gs://[Bucket Name]/predictions_00002.jsonl" \
  "gs://[Bucket Name]/predictions_00003.jsonl" \
  "gs://[Bucket Name]/predictions_00004.jsonl" \
  "gs://[Bucket Name]/predictions_00005.jsonl" \
  "gs://[Bucket Name]/predictions_00006.jsonl" \
  "gs://[Bucket Name]/predictions_00007.jsonl" \
  "gs://[Bucket Name]/predictions_00008.jsonl" \
  "gs://[Bucket Name]/predictions_00009.jsonl" \
  "gs://[Bucket Name]/predictions_00010.jsonl" \
  .

# Concat these jsonl files to a single jsonl file, predictions.jsonl
cat predictions_*.jsonl > predictions.jsonl

# Delete original .jsonl files
rm predictions_*.jsonl

# Then we can delete all data in the bucket:
gsutil -m rm -r gs://your-bucket-name/*
