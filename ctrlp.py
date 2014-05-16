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


def take(count, iterable):
    iterable = iter(iterable)
    while count:
        yield next(iterable)
        count = count - 1


class Item(object):
    def __init__(self, value, transformed):
        self.value = value
        self.transformed = transformed
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
    def value(self):
        return self.item.value

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

    @classmethod
    def full_unhighlighted(cls, string):
        return cls(string, [])

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self.match)

    def __len__(self):
        return len(self.match)

    def __iter__(self):
        return iter(self._merged) if self.indices else iter(())

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
        self.re_head = re.compile(re_prefix + re.escape(self.head))

        if len(pat) > 1:
            self.re = re.compile(
                re_prefix +
                u'*'.join(
                    u'(%(c)s)[^%(c)s]' % {'c': re.escape(c)} for c in pat[:-1]
                ) +
                (u'*?(%s)' % re.escape(pat[-1]))
            )
        else:
            self.re = re.compile(re_prefix + (u'(%s)' % re.escape(self.head)))

    def __len__(self):
        return len(self.pattern)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self.pattern)


class FuzzyMatch(object):
    inf = float('+INF')

    def __init__(self, pattern, item):
        self.item = item
        self.pattern = pattern
        self.string = item.transformed
        self._by_start = {}

        self._compute()

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return bool(self._chunks)

    def _compute(self):
        if not self.pattern:
            self._chunks = Chunks.full_unhighlighted(self.string)
            self.rank = self.inf
            return

        min_length = self.inf
        self._chunks = None

        for chunks in self._possible_chunks:
            if len(chunks) < min_length:
                self._chunks = chunks
                min_length = len(chunks)

        if self._chunks:
            self.rank = float(min_length)*len(self.string) / len(self.pattern)
        else:
            self.rank = self.inf
            self._chunks = Chunks.empty()

    @property
    def value(self):
        return self.item.value

    @property
    def _possible_chunks(self):
        cutout = len(self.string) - len(self.pattern) + 1
        for head in self.pattern.re_head.finditer(self.string, 0, cutout):
            start = head.start()

            if start in self._by_start:
                yield self._by_start[start]
                continue

            match = self.pattern.re.search(self.string, start)
            if not match:
                break

            groups = range(1, len(match.groups()) + 1)
            indices = (match.start(group) for group in groups)
            chunks = Chunks(match.group(0), indices)
            self._by_start[match.start()] = chunks

            yield chunks

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
        matches = (f(i) for i in self.transform(items) if i.value)
        return (SearchResult(match) for match in take(self.limit, sorted(
            (match for match in matches if match),
            key=lambda x: x.rank
        )))


class SearchResult(object):
    def __init__(self, match):
        self._match = match
        self.value = match.value.encode(CHARSET)

    def asdict(self):
        return dict(value=self.value, highlight=self.highlight)

    @property
    def highlight(self):
        return [
            dict((k, v.encode(CHARSET)) for k, v in part.items())
            for part in self._match.highlight
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
        factory = lambda i: RegexMatch(pattern, i)
    else:
        pattern = FuzzyPattern(pat)
        factory = lambda i: FuzzyMatch(pattern, i)

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
