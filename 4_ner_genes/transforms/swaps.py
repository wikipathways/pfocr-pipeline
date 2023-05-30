## Replaces character strings in uppercased words with matched strings in "swaps" dictionary.

# NOTE: entries should be upper and may contain non-alphanumerics
swap_list = {
'ALPHA':'A',
'BETA':'B', 
'GAMMA':'G', 
'DELTA':'D', 
'EPSILON':'E',
'KAPPA':'K',
'α':'A',
'β':'B',
'ß':'B',
'γ':'G',
'δ':'D',
'ε':'E',
'κ':'K',
'Θ':'Q',
'IKKP':'IKKG',
'IKKY':'IKKG',
'IFNY':'IFNG',
'SEMAY':'SEMAG',
'PLCY':'PLCG',
'TGFBRI':'TGFBR1',
'II':'2',
'III':'3',
'VE-CADHERIN':'CDH5',
'E-CADHERIN':'CDH1',
'N-CADHERIN':'CDH2',
'K-CADHERIN':'CDH6',
'R-CADHERIN':'CDH4',
'T-CADHERIN':'CDH13',
'M-CADHERIN':'CDH15',
'KSP-CADHERIN':'CDH16',
'LI-CADHERIN':'CDH17',
'BCATENIN':'CTNNB1',
'CALCINEURIN':'PPP3',
'P13K':'PI3K',
'NUCLEOLIN':'NCL',
'VITRONECTIN':'VTN',
'PLASMINOGEN':'PLG',
'PLASMIN':'PLG',
'EB13':'EBI3',
'TRADE':'TRADD',
'NRF-1':'NFE2L1',
'NRF-2':'NFE2L2',
'MGLUR':'GRM',
'AC':'ADCY',
'GRG':'TLE',
'NFKB':'NFKAPPAB',
'MAPKK':'MAP2K',
'Frizzled':'FZD',
'NMDAR':'GRIN',
'IKK':'IKK_complex',
'Cyclin-A1':'CCNA1',
'Cyclin-A2':'CCNA2',
'Cyclin-D1':'CCND1',
'Cyclin-D2':'CCND2',
'Cyclin-D3':'CCND3',
'Cyclin-E1':'CCNE1',
'Cyclin-E2':'CCNE2'
}

# This function goes through the swap_list and replaces the keys 
# found within each word with the corresponding values
def multipleReplace(text, wordDict):
    for key in wordDict:
        text = text.upper().replace(key, wordDict[key])
    return text

def swaps(input_list):
    results = list()
    for input_str in input_list:
        res = swaps_i(input_str)
        results.append(res)
    return [item for sublist in results for item in sublist]
   
def swaps_i(word):
    if len(word) > 0:
        multiRepWord = multipleReplace(word, swap_list)
        if len(multiRepWord) > 0:
            return [multiRepWord]
        else:
            return []
    else:
        return []

