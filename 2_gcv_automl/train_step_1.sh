#!/usr/bin/env bash

# chmod +x train_step_1.sh

# Install gsutil from https://cloud.google.com/storage/docs/gsutil_install

# Create a bucket. Keep bucket name secret. Caution: delete bucket after training.

# Upload folder of images to the google cloud storage, replace [Bucket Name] with your Bucket Name
gsutil -m cp -r ../../automl_train_15k_20200224 gs://[Bucket Name]

# This py script add bucket name prefix to existing csv with labels.
chmod +x train_prep_csv_input.py
python train_prep_csv_input.py

# Upload import_files.csv to bucket via shell or GUI first
gsutil -m cp -r import_files.csv gs://[Bucket Name]

# https://cloud.google.com/vertex-ai/docs/image-data/classification/create-dataset#aiplatform_import_data_image_classification_single_label_sample-drest

# Create dataset and replace Bucket ID
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @train_request_import.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/pfocr-384122/locations/us-central1/datasets/[Bucket ID]:import"

# Train the model
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @train_request_train.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/pfocr-384122/locations/us-central1/trainingPipelines"
