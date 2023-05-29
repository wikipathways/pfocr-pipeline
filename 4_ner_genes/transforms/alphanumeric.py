import re
normalize_re = re.compile('[^a-zA-Z0-9]')

def alphanumeric(input_list):
    results = list()
    for input_str in input_list:
        res = alphanumeric_i(input_str)
        results.append(res)
    return [item for sublist in results for item in sublist]

def alphanumeric_i(word):
    return [normalize_re.sub('', word)]
