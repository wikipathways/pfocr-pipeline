# Step 2. Classification by machine learning

The [ml_classification.ipynb notebook](#) details the steps to:
1. Prepare a dataset
2. Train a model
3. Predict pathways

This protocol uses Google Cloud Vision (GCV) AutoML to train a model to predict whether an image is a pathway diagram or not. The model is trained on manual classification data collected in February of 2020 (see automl_train_model_20200224.csv). The model can be reused for future predictions as long as it is maintained by the GCV project.

### Next Step

OCR is performed on the predicted pathway diagrams.