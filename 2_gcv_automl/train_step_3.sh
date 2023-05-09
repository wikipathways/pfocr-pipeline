#!/usr/bin/env bash
# Import Data
# chmod +x step_3.sh
# Upload import_files.csv to bucket via shell or GUI first
gsutil -m cp -r import_files.csv gs://[Bucket Name]

# https://cloud.google.com/vertex-ai/docs/image-data/classification/create-dataset#aiplatform_import_data_image_classification_single_label_sample-drest

# Create dataset and replace Bucket ID
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @train_request_import.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/pfocr-384122/locations/us-central1/datasets/[Bucket ID]:import"
