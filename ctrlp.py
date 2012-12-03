import os.path
import functools
import re
import vim_bridge

CHARSET = 'utf-8'

class Item(object):
    def __init__(self, transformed, string):
        self.encoded     = string
        self.original    = string.decode(CHARSET)
        self.transformed = transformed.decode(CHARSET)


class Processor(object):
    def filter(self, items, excluded=[]):
        items = list(i for i in items
                     if self.match(i) and i.original not in excluded)
        items.sort(key=self.sort_key)
        return items


class RegexProcessor(Processor):
    def __init__(self, pattern):
        self.pattern = re.compile(pattern or u'.*')
        self._sep    = os.path.sep

    def match(self, item):
        return self.pattern.match(item.transformed)

    def sort_key(self, item):
        return len(item.original.split(self._sep))


class FuzzyProcessor(Processor):
    def __init__(self, pattern):
        pattern      = pattern.lower()
        self.pattern = pattern
        self.pairs   = self._make_pairs(pattern)

    def match(self, item):
        index = 0
        string = item.transformed.lower()
        for char in self.pattern:
            index = string.find(char, index)
            if index == -1:
                return False
            index += 1
        return True

    def sort_key(self, item):
        return 1.0 - self._similarity_with_pattern(item)

    def _similarity_with_pattern(self, item):
        # A simple way to do string comparison, using the algorithm described
        # in http://www.catalysoft.com/articles/StrikeAMatch.html, from Simon
        # White.  Slightly modified to improve performance, but may not yield
        # the same results as the mentioned algorithm.
        pairs = self._make_pairs(item.transformed.lower())

        if pairs and not self.pairs:
            return 0.0

        union_len = len(pairs) + len(self.pairs)

        if not union_len:
            return 1.0

        def fn(count, pair):
            if pair in pairs:
                count += 1
                # Here is the key modification: instead of removing only one
                # element from the list of pairs, remove also all preceding
                # elements.
                # pairs.remove(pair)
                index = pairs.index(pair)
                del pairs[:index + 1]
            return count

        intersection_len = functools.reduce(fn, self.pairs, 0)
        return 2.0 * intersection_len / union_len

    def _make_pairs(self, string):
        return [string[i:i + 2] for i in range(len(string) - 1)]


@vim_bridge.bridged
def filter_ctrlp_list(items, pat, limit, mmode, ispath, crfile, isregex):
    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        factory = RegexProcessor
    else:
        factory = FuzzyProcessor

    processor = factory(pat.decode(CHARSET))

    excluded = []
    if ispath == 1 and crfile:
        excluded = [crfile.decode(CHARSET)]

    transformation = {
        'full-line':      lambda i: i,
        'filename-only':  os.path.basename,
        'first-non-tab':  lambda i: i.split('\t')[0],
        'until-last-tab': lambda i: '\t'.join(i.split('\t')[:-1]).strip('\t') if '\t' in i else i
    }[mmode]

    return [item.encoded for item in processor.filter(
        (Item(i, transformation(i)) for i in items),
        excluded
    )]
