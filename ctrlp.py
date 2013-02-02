import os.path
import functools
import re
try:
    import vim, vim_bridge
    HAS_VIM_BRIDGE = True
except ImportError:
    HAS_VIM_BRIDGE = False

CHARSET = 'utf-8'
SORT_THRESHOLD = 1000
CUTOUT = 100


class Item(object):
    def __init__(self, transformed, string):
        self.encoded     = string
        self.original    = string.decode(CHARSET)
        self.transformed = transformed.decode(CHARSET)


class Processor(object):
    def filter(self, items):
        filtered = list(i for i in items if self.match(i))
        if len(filtered) <= SORT_THRESHOLD:
            filtered.sort(key=self.sort_key)
        else:
            filtered.sort(key=lambda item: len(item.encoded))
        return filtered[:CUTOUT]


class RegexProcessor(Processor):
    def __init__(self, pattern):
        self.pattern = re.compile(pattern or u'.*')
        self._sep    = os.path.sep

    def match(self, item):
        return self.pattern.search(item.transformed)

    def sort_key(self, item):
        return len(item.original.split(self._sep))


class FuzzyProcessor(Processor):
    def __init__(self, pattern):
        pattern      = pattern.lower()
        self.pattern = pattern
        self.pairs   = list(self._make_pairs(pattern))
        self.bogus   = len(pattern) < 2

    def match(self, item):
        if self.bogus:
            return True

        string = item.transformed.lower()
        item._transformed_lower = string

        for char in self.pattern:
            head, sep, string = string.partition(char)
            if not sep:
                return False

        return True

    def sort_key(self, item):
        if self.bogus:
            return item.encoded

        return 1.0 - self._compute_similarity(item._transformed_lower)

    def _compute_similarity(self, string):
        # A simple way to do string comparison, using the algorithm described
        # in http://www.catalysoft.com/articles/StrikeAMatch.html, from Simon
        # White.  Slightly modified to improve performance, but may not yield
        # the same results as the mentioned algorithm.
        # pairs = tuple(self._make_pairs(string))
        union_len = len(string) - 1 + len(self.pairs)

        intersection_len = 0
        start = 0
        for pair in self.pairs:
            # Here is the key modification: instead of removing only one
            # element from the list of pairs, remove (ignore) also all
            # preceding elements.  This allows use to use the string
            # directly.
            found = string.find(pair, start)
            if found != -1:
                start = found + 1
                intersection_len += 1

        return 2.0 * intersection_len / union_len

    def _make_pairs(self, string):
        return (string[i:i + 2] for i in range(len(string) - 1))


def filter_ctrlp_list(items, pat, limit, mmode, ispath, crfile, isregex):
    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        factory = RegexProcessor
    else:
        factory = FuzzyProcessor

    processor = factory(pat.decode(CHARSET))

    if ispath == 1 and crfile and crfile in items:
        items.remove(crfile)

    transformation = {
        'full-line':      lambda i: i,
        'filename-only':  os.path.basename,
        'first-non-tab':  lambda i: i.split('\t')[0],
        'until-last-tab': lambda i: '\t'.join(i.split('\t')[:-1]).strip('\t') if '\t' in i else i
    }[mmode]

    return [item.encoded for item in processor.filter(
        (Item(i, transformation(i)) for i in items),
    )]

if HAS_VIM_BRIDGE:
    filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
