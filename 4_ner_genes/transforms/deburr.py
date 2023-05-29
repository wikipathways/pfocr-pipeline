# see https://stackoverflow.com/questions/517923/what-is-the-best-way-to-remove-accents-in-a-python-unicode-string

import unicodedata

def deburr(input_list):
    results = list()
    for input_str in input_list:
        res = deburr_i(input_str)
        results.append(res)
    return [item for sublist in results for item in sublist]
   
def deburr_i(input_str):
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return [u"".join([c for c in nfkd_form if not unicodedata.combining(c)])]
