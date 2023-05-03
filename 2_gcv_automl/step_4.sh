#!/usr/bin/env bash
# Train the model
# chmod +x step_4.sh
curl -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d @request.json \
    "https://us-central1-aiplatform.googleapis.com/v1/projects/pfocr-384122/locations/us-central1/trainingPipelines"
