## Named Entity Recognition 
# formerly "Post-processing" pp_classic.ipynb

## LOCAL CONFIGURATIONS
# data_dir = Path('/Users/alexpico/Dropbox (Gladstone)/pfocr-pipeline-runs/20230401/')
# ner_genes_dir = data_dir.joinpath('4_ner_genes/')
# gcv_ocr_dir = data_dir.joinpath('3_gcv_ocr/')
ner_genes_dir = Path('.')
gcv_ocr_dir = Path('../3_gcv_ocr/')
os.environ['R_HOME'] = '/Library/Frameworks/R.framework/Versions/4.1/Resources/'

## IMPORTS
import csv
import io
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path, PurePath
import pandas as pd
from functools import partial
import rpy2.robjects as ro
from rpy2.robjects import default_converter, pandas2ri
from rpy2.robjects.conversion import localconverter
from rpy2.robjects.lib.dplyr import DataFrame
from rpy2.robjects.packages import importr

#Import from local directory
#pip install confusable_homoglyphs
import transforms

#TODO: remove unused imports
# from itertools import zip_longest
# import hashlib
# import signal
# import subprocess
# import tempfile
# import warnings
# from IPython.display import Image
# from nltk.metrics import edit_distance

## READ/SAVE RDS FILES
pandas2ri.activate()
base = importr("base")
readRDS = ro.r["readRDS"]
saveRDS = ro.r["saveRDS"]

def rds2pandas(rds_path):
    r_df = readRDS(str(rds_path))
    with localconverter(ro.default_converter + pandas2ri.converter):
        pandas_df = ro.conversion.rpy2py(r_df)
    return pandas_df

def pandas2rds(pandas_df, rds_path):
    with localconverter(default_converter + pandas2ri.converter) as cv:
        r_df = DataFrame(pandas_df)

    saveRDS(r_df, str(rds_path))

## LOAD LEXICON
# Note: The lexicon file may contain redudant entries for the same gene symbol.
#       This is because the lexicon is built from multiple sources, including
#       aliases and bioentities. This is okay. All possible matches are returned.
with open(ner_genes_dir.joinpath("lexicon2020.json"), "r") as f:
    lexicon2020_df = pd.read_json(f)

# ncbigene_ids_by_symbol = (
#     lexicon2020_df[["ncbigene_id", "symbol"]]
#     .set_index("symbol")
#     .to_dict["ncbigene_id"]
# )
ncbigene_ids_by_symbol = (
    lexicon2020_df.groupby('symbol')['ncbigene_id']
    .apply(list).to_dict()
)
# lexicon_sources_by_symbol = (
#     lexicon2020_df[["source", "symbol"]]
#     .set_index("symbol")
#     .to_dict()["source"]
# )
lexicon_sources_by_symbol = (
    lexicon2020_df.groupby('symbol')['source']
    .apply(list).to_dict()
)

symbol_characters = set()
for symbol in ncbigene_ids_by_symbol.keys():
    for c in symbol:
        symbol_characters.add(c)
print(len(symbol_characters))

## LOAD FIGURE OCR DATA
# store file paths to .json files in gcv_ocr_dir as an array
gcv_ocr_data = []
for path in gcv_ocr_dir.glob("*.json"):
    gcv_ocr_data.append(
        {
            "figid": path.stem,
            "ocr_file_path": path
        }
    )
print(len(gcv_ocr_data))

# Prepare file paths to save results
run_timestamp = datetime.now().strftime("%Y%m%d%H%M")
successes_path = ner_genes_dir.joinpath(f"qc_successes_{run_timestamp}.txt")
fails_path = ner_genes_dir.joinpath(f"qc_fails_{run_timestamp}.txt")

with open(successes_path, "w") as f:
    f.write("")

with open(fails_path, "w") as f:
    f.write("")

# Define function to store lexicon matches
def store_match(
    matches_data,
    matches,
    transforms_applied,
    figid,
    ocr_text,
    symbol_id,
    lexicon_source,
    transformed_ocr_text,
):
    if transformed_ocr_text:
        matches.add(transformed_ocr_text)
        # for each index of symbol_id list corresponding to a match
        for i in range(len(symbol_id)):
            matches_data.append(
                {
                    "figid": figid,
                    "ncbigene_id": symbol_id[i],
                    "matched_ocr_text": ocr_text,
                    "lexicon_term": transformed_ocr_text,
                    "lexicon_source": lexicon_source[i],
                    "transforms_applied": transforms_applied,
                }
            )

# Define set and order of transforms to apply to OCR text
transforms_to_apply = [
    {
        "name": "stop",
        "transform": transforms.stop.stop,
    },
    {
        "name": "homoglyphs2ascii",
        "transform": lambda ocr_text: transforms.homoglyphs2ascii.homoglyphs2ascii(
            ocr_text, symbol_characters
        ),
    },
    {
        "name": "nfkc",
        "transform": transforms.nfkc.nfkc,
    },
    {
        "name": "deburr",
        "transform": transforms.deburr.deburr,
    },
    {
        "name": "expand",
        "transform": transforms.expand.expand,
    },
    {
        "name": "root",
        "transform": transforms.root.root,
    },
    {
        "name": "swaps",
        "transform": transforms.swaps.swaps,
    },
    {
        "name": "alphanumeric",
        "transform": transforms.alphanumeric.alphanumeric,
    },
]

# Define function to execute matching attempts on all OCR results
def match(matches_data, figid, ids_by_symbol, sources_by_symbol, all_raw_ocr_text):

    successes = list()
    fails = list()

    for line in all_raw_ocr_text.split("\n"):
        matches = set()

        ocr_texts = set()
        ocr_texts.add(line.replace(" ", ""))

        for w in line.split(" "):
            ocr_texts.add(w)

        for ocr_text in ocr_texts:
            transforms_applied = []
            transformed_ocr_texts = [ocr_text]
            for transform_to_apply in transforms_to_apply:
                transforms_applied.append(transform_to_apply["name"])
                for transformed_ocr_text_prev in transformed_ocr_texts:
                    transformed_ocr_texts = []
                    for transformed_ocr_text in transform_to_apply["transform"](
                        transformed_ocr_text_prev
                    ):
                        # perform match for original and uppercased ocr_texts (see elif)

                        try:
                            if transformed_ocr_text in ids_by_symbol:
                                store_match(
                                    matches_data,
                                    matches,
                                    transforms_applied,
                                    figid,
                                    ocr_text,
                                    ids_by_symbol[transformed_ocr_text],
                                    sources_by_symbol[transformed_ocr_text],
                                    transformed_ocr_text,
                                )
                            elif (
                                transformed_ocr_text.upper()
                                in ids_by_symbol
                            ):
                                store_match(
                                    matches_data,
                                    matches,
                                    transforms_applied,
                                    figid,
                                    ocr_text,
                                    ids_by_symbol[
                                        transformed_ocr_text.upper()
                                    ],
                                    sources_by_symbol[
                                        transformed_ocr_text.upper()
                                    ],
                                    transformed_ocr_text.upper(),
                                )
                            else:
                                transformed_ocr_texts.append(
                                    transformed_ocr_text
                                )

                        #    except TimedOutExc as e:
                        #        print "took too long"

                        except (Exception) as e:
                            print("Unexpected Error:", e)
                            print("figid:", figid)
                            print("ocr_text:", ocr_text)
                            print(
                                "transformed_ocr_text:",
                                transformed_ocr_text,
                            )
                            print(
                                "transforms_applied:",
                                transforms_applied,
                            )
                            raise

            if len(matches) == 0:
                store_match(
                    matches_data,
                    matches,
                    transforms_applied,
                    figid,
                    ocr_text,
                    None,
                    None,
                    None,
                )
        if len(matches) > 0:
            successes.append(line + " => " + " & ".join(matches))
        else:
            fails.append(line)

    with open(successes_path, "a") as f:
        f.write(figid + "\n")
        for success in successes:
            f.write(success + "\n")
        f.write("\n")

    with open(fails_path, "a") as f:
        f.write(figid + "\n")
        for fail in fails:
            f.write(fail + "\n")
        f.write("\n")

    #DEBUG print lines
    # print(f"{figid}")
    # print(f"  successes")
    # print(f"  {successes}")
    # print(f"  fails")
    # print(f"  {fails}")
    # print("")

## RUN NER FOR ALL FIGURES
gene_matches_data = list()
for x in gcv_ocr_data:

    ocr_file_path = Path(x["ocr_file_path"])
    with ocr_file_path.open("r", encoding="utf8") as f:
        ocr_output = json.load(f)
    if len(ocr_output) == 0:
        print(f"empty ocr_file_path: {ocr_file_path}")
        continue

    ocr_text = ocr_output[0]["description"]

    figid = x["figid"]

    try:
        match(gene_matches_data, figid, ncbigene_ids_by_symbol, lexicon_sources_by_symbol, ocr_text)
    except (Exception) as e:
        print("Unexpected Error:", e)
        print("figid:", figid)
        #DEBUG print lines
        #        print("word:", word)
        #        print(
        #            "transformed_word:",
        #            transformed_word,
        #        )
        #        print(
        #            "transforms_applied:",
        #            transforms_applied,
        #        )
        raise

# Prep dataframe for export
gene_matches_df = pd.DataFrame(gene_matches_data)
gene_matches_exportable_results_df = gene_matches_df.copy(deep=True)
gene_matches_exportable_results_df["transforms_applied"] = gene_matches_df[
    "transforms_applied"
].str.join(",")

# Export all results (including duplicate matches per figure)
pandas2rds(
    gene_matches_exportable_results_df,
    ner_genes_dir.joinpath(f"qc_results_{run_timestamp}.rds"),
)

# Subset, order and rename columns
gene_matches_export_columns = [
    "figid",
    "matched_ocr_text",
    "lexicon_term",
    "ncbigene_id",
    "lexicon_source",
]
gene_matches_df = gene_matches_df[gene_matches_export_columns]
gene_matches_df.columns = [
    "figid",
    "word",
    "symbol",
    "entrez",
    "source"
]

# Deduplicate for a more efficient export
gene_matches_df = gene_matches_df.drop_duplicates()

pandas2rds(
    gene_matches_df,
    ner_genes_dir.joinpath(f"pfocr_genes_{run_timestamp}.rds"),
)
