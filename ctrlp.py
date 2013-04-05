import argparse
import os.path
import re
import sys

try:
    import vim, vim_bridge
    HAS_VIM_BRIDGE = True
except ImportError:
    HAS_VIM_BRIDGE = False

try:
    unicode
    PY3 = False
except NameError:
    PY3 = True

CHARSET = 'utf-8'
CUTOUT = 100


class Item(object):
    def __init__(self, value, transformed):
        self.value = value
        self.transformed = transformed
        self.transformed_lower = transformed.lower()


class Processor(object):
    def filter(self, items):
        filtered = list(i for i in items if self.match(i))
        filtered.sort(key=self.sort_key)
        return filtered[:self.limit]


class RegexProcessor(Processor):
    def __init__(self, pattern, limit):
        self.pattern = re.compile(pattern or u'.*')
        self._sep = os.path.sep
        self.limit = limit

    def match(self, item):
        return self.pattern.search(item.transformed)

    def sort_key(self, item):
        return len(item.original.split(self._sep))


class FuzzyProcessor(Processor):
    def __init__(self, pattern, limit):
        pattern = pattern.lower()
        self.pattern = pattern
        self.pairs = list(self._make_pairs(pattern))
        if len(pattern) < 2:
            self.match = lambda item: True
            self.sort_key = lambda item: item.value
        self.limit = limit

    def match(self, item):
        string = item.transformed_lower

        for char in self.pattern:
            head, sep, string = string.partition(char)
            if not sep:
                return False

        return True

    def sort_key(self, item):
        # A simple way to do string comparison, using the algorithm described
        # in http://www.catalysoft.com/articles/StrikeAMatch.html, from Simon
        # White.  Slightly modified to improve performance, but may not yield
        # the same results as the mentioned algorithm.
        string = item.transformed_lower
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

        return 1.0 - (2.0 * intersection_len / union_len)

    def _make_pairs(self, string):
        return (string[i:i + 2] for i in range(len(string) - 1))


def _full_line_transform(items):
    return (Item(i, i) for i in items)


def _filename_only_transform(items):
    return (Item(i, os.path.basename(i)) for i in items)


def _first_non_tab_transform(items):
    return (Item(i, i.split('\t')[0]) for i in items)


def _until_last_tab_transform(items):
    return (Item(
        i,
        '\t'.join(i.split('\t')[:-1]).strip('\t') if '\t' in i else i
    ) for i in items)


def filter_ctrlp_list(items, pat, limit, mmode, ispath, crfile, isregex):
    limit = CUTOUT

    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        factory = RegexProcessor
    else:
        factory = FuzzyProcessor

    processor = factory(pat.decode(CHARSET), limit)

    if ispath and crfile and crfile in items:
        items.remove(crfile)

    transform = {
        'full-line': _full_line_transform,
        'filename-only': _filename_only_transform,
        'first-non-tab': _first_non_tab_transform,
        'until-last-tab': _until_last_tab_transform,
    }[mmode]

    u_items = (i.decode(CHARSET) for i in items)
    results = [item.value.encode(CHARSET)
               for item in processor.filter(transform(u_items))]

    if limit:
        return results[:limit]

    return results

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('pattern')
    parser.add_argument('-m', '--match-mode',
                        dest='match_mode',
                        default='full-line')
    parser.add_argument('-i', '--ignore-file', dest='ignore_file')
    parser.add_argument('-r', '--is-regexp',
                        default=False,
                        dest='is_regex',
                        action='store_true')
    # parser.add_argument('-l', '--limit', type=int)

    args = parser.parse_args()

    pattern = args.pattern
    match_mode = args.match_mode
    is_regex = args.is_regex

    if args.ignore_file:
        current_file = args.ignore_file
        is_path = True
    else:
        current_file = ''
        is_path = False

    input_lines = (line.strip() for line in sys.stdin.readlines())

    if PY3:
        pattern = pattern.encode(CHARSET)
        current_file = current_file.encode(CHARSET)
        input_lines = (line.encode(CHARSET) for line in input_lines)

    results = filter_ctrlp_list(
        input_lines,
        pattern,
        args.limit,
        match_mode,
        is_path,
        current_file,
        is_regex
    )

    if PY3:
        sys.stdout.write('\n'.join(item.decode(CHARSET) for item in results))
        sys.stdout.write('\n')
    else:
        sys.stdout.write('\n'.join(results))
        sys.stdout.write('\n')

    sys.stdout.flush()

if HAS_VIM_BRIDGE:
    filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
