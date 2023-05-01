import pandas as pd

label = pd.read_csv("automl_train_15k_20200224.csv", header = None)

label.columns = ["file_name", "label"]

# Replace Bucket Name with your actual Bucket
label["file_name"] = [Bucket Name] + label["file_name"].astype(str)

label.to_csv("import_files.csv", index=False)
