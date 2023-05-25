#!/usr/bin/env bash

# chmod +x predict_step_1.sh

# Upload images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r ../1_images gs://[Bucket Name]

# Get images urls in the bucket
 gsutil ls -r gs://[Bucket Name]/1_images/ > predict_images.csv

# This py script convert gs url csv file to jsonl file. Google cloud only accepts jsonl.
chmod +x predict_prep_jsonl_input.py
python predict_prep_jsonl_input.py

# Put this jsonl back to the bucket
gsutil -m cp -r predict_images.jsonl gs://[Bucket Name]

# Predict images
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @predict_request.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/[Project Name]/locations/us-central1/batchPredictionJobs"
