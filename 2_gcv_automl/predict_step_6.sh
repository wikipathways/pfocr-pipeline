# When the prediction is done, the result will be stored in the bucket.
# Download all jsonl files from predictions_00001.jsonl to predcitions_00010 to your machine.
# We can easily concat these jsonl files to a single jsonl file and then run process_raw_rds.R to process the data.
# Then we can delete all data in the bucket:

gsutil -m rm -r gs://your-bucket-name/*
