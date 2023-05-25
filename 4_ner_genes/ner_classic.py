## Named Entity Recognition (classic)
# formerly "Post-processing" pp_classic.ipynb

## LOCAL CONFIGURATIONS
data_dir = Path('/Users/alexpico/Dropbox (Gladstone)/pfocr-pipeline/20230401/')
ner_genes_dir = data_dir.joinpath('4_ner_genes/')
gcv_ocr_dir = data_dir.joinpath('3_gcv_ocr/')
#ner_genes_dir = Path('.')
#gcv_ocr_dir = Path('../3_gcv_ocr/')
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

with open(ner_genes_dir.joinpath("lexicon2020.json"), "r") as f:
    lexicon2020_df = pd.read_json(f)
lexicon2020_df

ncbigene_ids_by_symbol = (
    lexicon2020_df[["ncbigene_id", "symbol"]]
    .set_index("symbol")
    .to_dict()["ncbigene_id"]
)

symbol_characters = set()
for symbol in ncbigene_ids_by_symbol.keys():
    for c in symbol:
        symbol_characters.add(c)
print(len(symbol_characters))

## LOAD FIGURE OCR DATA
figures2021_new_data = [
    x
    for x in figures2021_data
    if x["new"]
    and Path(x["ocr_output_path"]).exists()
    and x["classification"] == "pathway"
]
print(len(figures2021_new_data))


run_timestamp = datetime.now().strftime("%Y%m%d%H%M")



results_path = images_dir.joinpath(f"results{run_timestamp}.tsv")
successes_path = images_dir.joinpath(f"successes{run_timestamp}.txt")
fails_path = images_dir.joinpath(f"fails{run_timestamp}.txt")

next_pfocr_id_path = images_dir.joinpath("next_pfocr_id_path.txt")


with open(next_pfocr_id_path, "w") as f:
    f.write("")

with open(results_path, "w") as f:
    f.write(
        "\t".join(["pfocr_id", "ncbigene_id", "ocr_text", "lexicon_term"])
        + "\n"
    )

with open(successes_path, "w") as f:
    f.write("")

with open(fails_path, "w") as f:
    f.write("")


def attempt_match(
    matches_data,
    matches,
    transforms_applied,
    pfocr_id,
    ocr_text,
    symbol_id,
    transformed_ocr_text,
):
    if transformed_ocr_text:
        matches.add(transformed_ocr_text)
        with open(results_path, "a") as f:
            f.write(
                "\t".join(
                    [pfocr_id, str(symbol_id), ocr_text, transformed_ocr_text]
                )
                + "\n"
            )

        matches_data.append(
            {
                "pfocr_id": pfocr_id,
                "ncbigene_id": symbol_id,
                "matched_ocr_text": ocr_text,
                "lexicon_term": transformed_ocr_text,
                "transforms_applied": transforms_applied,
            }
        )

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


def match(matches_data, pfocr_id, symbol_ids_by_symbol, all_raw_ocr_text):
    with open(next_pfocr_id_path, "a") as f:
        f.write(pfocr_id)

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
                            if transformed_ocr_text in symbol_ids_by_symbol:
                                attempt_match(
                                    matches_data,
                                    matches,
                                    transforms_applied,
                                    pfocr_id,
                                    ocr_text,
                                    symbol_ids_by_symbol[transformed_ocr_text],
                                    transformed_ocr_text,
                                )
                            elif (
                                transformed_ocr_text.upper()
                                in symbol_ids_by_symbol
                            ):
                                attempt_match(
                                    matches_data,
                                    matches,
                                    transforms_applied,
                                    pfocr_id,
                                    ocr_text,
                                    symbol_ids_by_symbol[
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
                            print("pfocr_id:", pfocr_id)
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
                attempt_match(
                    matches_data,
                    matches,
                    transforms_applied,
                    pfocr_id,
                    ocr_text,
                    None,
                    None,
                )
        if len(matches) > 0:
            successes.append(line + " => " + " & ".join(matches))
        else:
            fails.append(line)

    with open(successes_path, "w") as f:
        for success in successes:
            f.write(success + "\n")
        f.write("\n")

    with open(fails_path, "w") as f:
        for fail in fails:
            f.write(fail + "\n")
        f.write("\n")

    # print(f"{pfocr_id}")
    # print(f"  successes")
    # print(f"  {successes}")
    # print(f"  fails")
    # print(f"  {fails}")
    # print("")


genes_2021_data = list()
for x in figures2021_new_data:

    ocr_output_path = Path(x["ocr_output_path"])
    with ocr_output_path.open("r", encoding="utf8") as f:
        ocr_output = json.load(f)
    if len(ocr_output) == 0:
        print(f"empty ocr_output_path: {ocr_output_path}")
        continue

    ocr_text = ocr_output[0]["description"]

    pfocr_id = x["pfocr_id"]

    try:
        match(genes_2021_data, pfocr_id, ncbigene_ids_by_symbol, ocr_text)
    except (Exception) as e:
        print("Unexpected Error:", e)
        print("pfocr_id:", pfocr_id)
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

genes_2021_df = pd.DataFrame(genes_2021_data)

genes_2021_df["pfocr_year"] = 2021

genes_2021_exportable_results_df = genes_2021_df.copy(deep=True)
genes_2021_exportable_results_df["transforms_applied"] = genes_2021_df[
    "transforms_applied"
].str.join(",")
pandas2rds(
    genes_2021_exportable_results_df,
    images_dir.joinpath(f"results{run_timestamp}.rds"),
)
genes_2021_exportable_results_df.to_csv(
    str(images_dir.joinpath(f"results{run_timestamp}.csv"))
)

genes_2021_df


# I don't currently have all the 2021 data to fill in the same set of columns we used in 2020, so some of them are commented out below.


genes_2021_export_columns = [
    "pfocr_id",
    "matched_ocr_text",
    "lexicon_term",
    # "lexicon_term_source",
    # "hgnc_symbol",
    "ncbigene_id",
    # "unique_gene_count",
    "pfocr_year",
]

pandas2rds(
    genes_2021_df[genes_2021_export_columns],
    images_dir.joinpath("pfocr_genes_2021.rds"),
)








