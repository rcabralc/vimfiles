import argparse
import os.path
import re
import sys

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


class Item(object):
    def __init__(self, value, transformed):
        self.value = value
        self.transformed = transformed


class RegexTerm(object):
    _sep = os.path.sep

    def __init__(self, pattern, re_pattern, item):
        self.item = item
        self.string = item.transformed
        self.pattern = pattern
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
    def value(self):
        return self.item.value

    @property
    def highlight(self):
        if not self.pattern:
            return []

        start, end = self._match.span()
        beginning = self.string[:start]
        middle = self.string[start:end]
        ending = self.string[end:]
        return [dict(beginning=beginning, middle=middle, ending=ending)]


class Chunks(object):
    def __init__(self, match):
        self.match = match
        self._indices = None

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self.match)

    def __iter__(self):
        return iter(self._merged) if self.match else iter(())

    @property
    def indices(self):
        if self._indices is None:
            match = self.match
            groups = match.groups()
            self._indices = list(match.start(i + 1)
                                 for i, _ in enumerate(groups))
        return self._indices

    @property
    def _merged(self):
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


class UnhighlightedChunks(object):
    def __init__(self, string):
        self.length = len(string)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    def __iter__(self):
        return iter(())


class FuzzyPattern(object):
    def __init__(self, pattern):
        pattern_lower = pattern.lower()

        if pattern_lower != pattern:
            pat = self.pattern = pattern
            re_prefix = u'(?u)'
        else:
            pat = self.pattern = pattern_lower
            re_prefix = u'(?iu)'

        self.head = self.pattern[0:1]
        if self.head:
            regex = re.compile(
                re_prefix +
                u''.join(
                    u'(%(c)s)[^%(c)s]*?' % {'c': re.escape(c)}
                    for c in pat[:-1]
                ) +
                (u'(%s)' % re.escape(pat[-1]))
            )
        else:
            regex = re.compile(u'')

        self.search = regex.search

    def __len__(self):
        return len(self.pattern)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self.pattern)


class FuzzyTerm(object):
    inf = float('+INF')

    def __init__(self, pattern, item):
        self.item = item
        self.pattern = pattern
        self.string = item.transformed
        self.string_length = len(self.string)
        self.pattern_length = len(self.pattern)

        self._compute()

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self._chunks)

    def _compute(self):
        if not self.pattern:
            self._chunks = UnhighlightedChunks(self.string)
            self.rank = self.inf
            return

        self.rank = self.inf
        min_length = self.inf
        best_match = None

        for match_length, match in self._possible_matches:
            if match_length < min_length:
                best_match = match
                min_length = match_length
            if min_length == self.pattern_length:
                break

        if best_match:
            self._chunks = Chunks(match)
            self.rank = (
                float(min_length) * self.string_length / self.pattern_length
            )
        else:
            self._chunks = Chunks(None)

    @property
    def value(self):
        return self.item.value

    @property
    def _possible_matches(self):
        if self.pattern_length > self.string_length:
            return

        cutout = self.string_length - self.pattern_length + 1
        search = self.pattern.search

        pos = self.string.find(self.pattern.head)
        if not ~pos:
            return

        while pos < cutout:
            match = search(self.string, pos)
            if not match:
                return

            leftmost = match.start()
            yield ((match.end() - leftmost), match)

            pos = self.string.find(self.pattern.head, leftmost + 1)
            if not ~pos:
                return

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
    def __init__(self, factory, transform, limit):
        self.factory = factory
        self.transform = transform
        self.limit = limit

    def matches(self, items):
        f = self.factory
        terms = (f(i) for i in self.transform(items) if i.value)
        return (SearchResult(term) for term in sorted(
            (term for term in terms if term),
            key=lambda x: x.rank
        )[:self.limit])


class SearchResult(object):
    def __init__(self, term):
        self._term = term
        self.value = term.value.encode(CHARSET)

    def asdict(self):
        return dict(value=self.value, highlight=self.highlight)

    @property
    def highlight(self):
        return [
            dict((k, v.encode(CHARSET)) for k, v in part.items())
            for part in self._term.highlight
        ]


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


def filter(items, pat, limit, mmode, ispath, crfile, isregex):
    limit = int(limit)
    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        pattern = re.compile(u'(?iu)' + pat if pat else u'.*')
        factory = lambda i: RegexTerm(pat, pattern, i)
    else:
        pattern = FuzzyPattern(pat)
        factory = lambda i: FuzzyTerm(pattern, i)

    if ispath and crfile and crfile in items:
        items.remove(crfile)

    transform = dict(
        fullline=_full_line_transform,
        filenameonly=_filename_only_transform,
        firstnontab=_first_non_tab_transform,
        untillasttab=_until_last_tab_transform,
    )[mmode.replace('-', '')]

    return Search(factory, transform, limit).matches(items)


def filter_ctrlp_list(items, pat, limit, mmode, ispath, crfile, isregex):
    try:
        return [result.asdict() for result in
                filter(items, pat, limit, mmode, ispath, crfile, isregex)]
    except Exception:
        if __name__ == '__main__':
            raise

        import traceback
        return list(reversed(
            dict(highlight=[], value=line.encode(CHARSET))
            for line in traceback.format_exception(*sys.exc_info())
        ))


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

    results = filter(
        input_lines,
        pattern,
        args.limit if args.limit > 0 else 1,
        match_mode,
        is_path,
        current_file,
        is_regex
    )

    sys.stdout.write(u'\n'.join(result.value.decode(CHARSET)
                                for result in results))
    sys.stdout.write(u'\n')
    sys.stdout.flush()


if HAS_VIM_BRIDGE:
    try:
        filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
    except ImportError:
        # Vim Bridge tries to import vim during the call to bridge().
        pass
