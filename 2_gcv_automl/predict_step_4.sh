#!/usr/bin/env bash

# chmod +x predict_step_4.sh

# Put this jsonl back to the bucket
gsutil -m cp -r predict_images.jsonl gs://[Bucket Name]
