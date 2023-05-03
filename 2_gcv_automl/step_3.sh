#!/usr/bin/env bash
# Import Data
# chmod +x step_3.sh
#Import import_files.csv to bucket via shell or GUI first

curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @request_import.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/pfocr-384122/locations/us-central1/datasets/1379990446951890944:import"
