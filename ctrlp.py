import argparse
import os.path
import re
import sys
import traceback

try:
    import vim_bridge
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
        self._levels = None

    @property
    def levels(self):
        if self._levels is not None:
            return self._levels
        self._levels = len(self.value.split(os.path.sep))
        return self._levels


class RegexMatch(object):
    _sep = os.path.sep

    def __init__(self, re_pattern, item):
        self.item = item
        self.string = item.transformed
        self._match = re_pattern.search(self.string)

        if not self._match:
            self.rank = float('+INF')
        else:
            start, end = self._match.span()
            self.rank = 1 - float(end - start) / len(self.string)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self._match)

    @property
    def highlight(self):
        start, end = self._match.span()
        beginning = self.string[:start]
        middle = self.string[start:end]
        ending = self.string[end:]
        return [dict(beginning=beginning, middle=middle, ending=ending)]


class Chunks(object):
    def __init__(self, match, indices):
        self.match = match
        self.indices = tuple(indices)

    @classmethod
    def empty(cls):
        return cls(u'', [])

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self.match)

    def __len__(self):
        return len(self.match)

    def __iter__(self):
        if not self.indices:
            return

        (head,), tail = self.indices[0:1], self.indices[1:]
        chunks = [[head]]
        (chunk,) = chunks
        for i in tail:
            if i == chunk[-1] + 1:
                chunk.append(i)
            else:
                chunk = [i]
                chunks.append(chunk)

        for chunk in chunks:
            yield chunk[0], chunk[-1] + 1


class FuzzyMatch(object):
    inf = float('+INF')

    def __init__(self, head, tail, item):
        self.item = item
        self.string = item.transformed_lower
        self._pattern_head = head
        self._pattern_tail = tail

        self._compute()

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self._chunks)

    def _compute(self):
        if not self._pattern_head:
            self._chunks = Chunks(self.string, [])
            self.rank = self.inf
            return

        min_length = self.inf
        self._chunks = None

        # Often the pattern is a substring in the string.
        start = self.string.find(self._pattern_head + self._pattern_tail)
        if ~start:
            min_length = len(self._pattern_head) + len(self._pattern_tail)
            end = start + min_length
            self._chunks = Chunks(self.string[start:end],
                                  tuple(range(start, end)))
        else:
            for chunks in self._possible_chunks:
                if len(chunks) < min_length:
                    self._chunks = chunks
                    min_length = len(chunks)

        if self._chunks:
            pattern_length = len(self._pattern_head) + len(self._pattern_tail)
            self.rank = float(min_length) * len(self.string) / pattern_length
        else:
            self.rank = self.inf
            self._chunks = Chunks.empty()

    @property
    def _possible_chunks(self):
        for start in self._start_indices:
            chunks = self._chunks_at(start)
            if chunks:
                yield chunks

    @property
    def _start_indices(self):
        max_index = len(self.string) - len(self.pattern)
        if max_index >= 0:
            string = self.string[:max_index + 1]
        else:
            string = u''
        lengths = [len(s) for s in string.split(self._pattern_head)]
        previous = 0
        for l in lengths[:-1]:
            yield previous + l
            previous += l + 1

    def _chunks_at(self, start):
        current = start + 1
        find = self.string.find
        indices = [start]

        for char in self._pattern_tail:
            found = find(char, current)
            if not ~found:
                return Chunks.empty()
            indices.append(found)
            current = found + 1

        return Chunks(self.string[start:current], indices)

    @property
    def highlight(self):
        matches = []
        for start, end in self._chunks:
            matches.append(dict(
                beginning=self.string[:start],
                middle=self.string[start:end],
                ending=self.string[end:]
            ))

        return matches


class Search(object):
    def __init__(self, factory):
        self.factory = factory

    def matches(self, items):
        f = self.factory
        matches = (f(i) for i in items if i.value)
        return [item for item in sorted(
            (match for match in matches if match),
            key=lambda x: x.rank
        )]


def _full_line_transform(items):
    return (Item(i, i) for i in items)


def _filename_only_transform(items):
    return (Item(i, os.path.basename(i)) for i in items)


def _first_non_tab_transform(items):
    return (Item(i, i.split(u'\t')[0]) for i in items)


def _until_last_tab_transform(items):
    return (Item(
        i,
        u'\t'.join(i.split(u'\t')[:-1]).strip(u'\t') if u'\t' in i else i
    ) for i in items)


def filter_ctrlp_list(items, pat, limit, mmode, ispath, crfile, isregex):
    limit = int(limit)
    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        pattern = re.compile(u'(?iu)' + pat if pat else u'.*')
        factory = lambda i: RegexMatch(pattern, i)
    else:
        pattern = pat.lower()
        head = pattern[0:1]
        tail = pattern[1:]
        factory = lambda i: FuzzyMatch(head, tail, i)

    search = Search(factory)

    if ispath and crfile and crfile in items:
        items.remove(crfile)

    transform = {
        u'full-line': _full_line_transform,
        u'filename-only': _filename_only_transform,
        u'first-non-tab': _first_non_tab_transform,
        u'until-last-tab': _until_last_tab_transform,
    }[mmode]

    if not PY3:
        items = [i.decode(CHARSET) for i in items]

    try:
        return [
            dict(
                match=match.item.value.encode(CHARSET),
                highlight=[
                    dict((k, v.encode(CHARSET)) for k, v in part.items())
                    for part in match.highlight
                ]
            )
            for match in search.matches(transform(items))[:CUTOUT]
        ]
    except Exception:
        if __name__ == '__main__':
            raise

        return [
            dict(highlight=[], match=line.encode(CHARSET))
            for line in traceback.format_exception(*sys.exc_info())
        ]

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
    parser.add_argument('-l', '--limit', dest="limit", default=10, type=int)

    args = parser.parse_args()

    pattern = args.pattern
    match_mode = args.match_mode
    is_regex = args.is_regex

    if args.ignore_file:
        current_file = args.ignore_file
        is_path = True
    else:
        current_file = u''
        is_path = False

    input_lines = (line.strip() for line in sys.stdin.readlines())

    if not PY3:
        pattern = pattern.decode(CHARSET)
        current_file = current_file.decode(CHARSET)
        input_lines = (line.decode(CHARSET) for line in input_lines)

    results = filter_ctrlp_list(
        input_lines,
        pattern,
        args.limit,
        match_mode,
        is_path,
        current_file,
        is_regex
    )

    sys.stdout.write(u'\n'.join(item['match'].decode(CHARSET)
                                for item in results))
    sys.stdout.write(u'\n')

    sys.stdout.flush()

if HAS_VIM_BRIDGE:
    try:
        filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
    except ImportError:
        # Vim Bridge tries to import vim during the call to bridge().
        pass
