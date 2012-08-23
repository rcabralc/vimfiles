from collections import namedtuple

import os.path
import re
import functools


def filterCtrlpList(items, pat, limit, mmode, ispath, crfile, isregex):
    sep = os.path.sep

    def similarity(s, pat_pairs):
        # A simple way to do string comparison, using the algorithm described
        # in http://www.catalysoft.com/articles/StrikeAMatch.html, from Simon
        # White.  Slightly modified to improve performance, but may not yield
        # the same results as the mentioned algorithm.
        s_pairs = [s[i:i + 2] for i in range(len(s) - 1)]

        if s_pairs and not pat_pairs:
            return 0.0

        union_len = len(s_pairs) + len(pat_pairs)

        if not union_len:
            return 1.0

        def fn(count, pair):
            if pair in s_pairs:
                count += 1
                # Here is the key modification: instead of removing only one
                # element from the list of pairs, remove also all preceding
                # elements.
                # s_pairs.remove(pair)
                index = s_pairs.index(pair)
                del s_pairs[:index + 1]
            return count

        intersection_len = functools.reduce(fn, pat_pairs, 0)
        return 2.0 * intersection_len / union_len

    def rank_fn(pat):
        if isregex:
            return lambda result: len(result.item.split(sep))
        pat_pairs = tuple(pat[i:i + 2] for i in range(len(pat) - 1))
        return lambda result: 1.0 - similarity(result.transformed_item,
                                               pat_pairs)

    def match_fn(pat):
        if isregex:
            return re.compile(pat or '.*').search
        def fuzzy_match(transformed_item):
            index = 0
            for char in pat:
                index = transformed_item.find(char, index)
                if index == -1:
                    return False
                index += 1
            return True
        return fuzzy_match

    def transform_fn(mmode):
        return {
            'full-line':      lambda i: i,
            'filename-only':  os.path.basename,
            'first-non-tab':  lambda i: i.split('\t')[0],
            'until-last-tab': lambda i: '\t'.join(i.split('\t')[:-1]).strip('\t') if '\t' in i else i
        }[mmode]

    if ispath == 1 and crfile:
        try:
            items.remove(crfile)
        except ValueError:
            pass

    match = match_fn(pat)
    rank = rank_fn(pat)
    transform = transform_fn(mmode)

    filtered_result = namedtuple('filteredresult', 'item transformed_item')

    transformed = ((i, transform(i)) for i in items)
    filtered    = (filtered_result(i, ti) for i, ti in transformed if match(ti))
    final       = [i for i, ti in sorted(filtered, key=rank)[:limit]]

    return final
