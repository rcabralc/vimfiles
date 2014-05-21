from __future__ import division
from __future__ import unicode_literals

import argparse
import functools
import operator
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
    _transformed_lower = None

    def __init__(self, value, transformed):
        self.value = value
        self.transformed = transformed

    @property
    def transformed_lower(self):
        if self._transformed_lower is None:
            self._transformed_lower = self.transformed.lower()
        return self._transformed_lower


class RegexTerm(object):
    def __init__(self, pattern, re_pattern, item):
        self.item = item
        self.string = item.transformed
        self.pattern = pattern
        self._match = re_pattern.search(self.string)

        if not self._match:
            self.rank = 1
        else:
            start, end = self._match.span()
            self.rank = 1 - (end - start) / len(self.string)

    def matched(self):
        return bool(self._match)

    @property
    def value(self):
        return self.item.value

    @property
    def highlight(self):
        if not self.pattern:
            return []

        start, end = self._match.span()
        beginning = self.value[:start]
        middle = self.value[start:end]
        ending = self.value[end:]
        return [dict(beginning=beginning, middle=middle, ending=ending)]


class UnhighlightedFuzzyMatch(object):
    indices = frozenset()
    pattern_length = 0

    def __init__(self, item):
        self.length = len(item.transformed)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    def __iter__(self):
        return iter(())

    def __len__(self):
        return self.length

    def merge(self, other):
        return other.merge(self)


class FuzzyMatch(object):
    _indices = None
    _length = None

    def __init__(self, match, pattern=None):
        self.match = match
        self.pattern = pattern

        if match and pattern:
            self.pattern_length = pattern.length

    def __len__(self):
        if self._length is None:
            if self.match:
                # Avoid computing indices here if a match is available.
                self._length = len(self.match.groups()[0])
            elif self.indices:
                self._length = max(self.indices) - min(self.indices)
            else:
                self._length = 0
        return self._length

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        if self.match is not None:
            return True
        return len(self.indices) > 0

    def __iter__(self):
        if not self.indices:
            return

        indices = sorted(self.indices)

        (head,), tail = indices[0:1], indices[1:]
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

    def merge(self, other):
        new_item = FuzzyMatch(None)
        new_item._indices = self.indices.union(other.indices)
        return new_item

    @property
    def indices(self):
        if self._indices is None:
            indices = []

            if self.match and self.pattern:
                string = self.match.string
                pattern = self.pattern.pattern
                pattern_length = self.pattern_length
                current = self.match.start()
                pos = 0
                find = string.find

                while pos < pattern_length:
                    current = find(pattern[pos], current)
                    indices.append(current)
                    pos += 1
                    current += 1

            self._indices = frozenset(indices)

        return self._indices


FuzzyMatch.none = FuzzyMatch(None)
FuzzyMatch.unhighlighted = UnhighlightedFuzzyMatch


class FuzzyPattern(object):
    def __init__(self, pattern):
        pattern_lower = pattern.lower()

        if pattern_lower != pattern:
            pat = self.pattern = pattern
            self._ignore_case = False
        else:
            pat = self.pattern = pattern_lower
            self._ignore_case = True

        self.head = pat[0:1]
        if self.head:
            self.regex = re.compile(
                '(?u)(?=((%s)' % re.escape(self.head) +
                ''.join(
                    '[^%(c)s]*?(%(c)s)' % {'c': re.escape(c)}
                    for c in pat[1:]
                ) + '))'
            )
        else:
            self.regex = re.compile('')

        self.length = len(pat)
        if not pat:
            self.find_shortest = FuzzyMatch.unhighlighted

    def __len__(self):
        return self.length

    def find_shortest(self, item):
        if self._ignore_case:
            string = item.transformed_lower
        else:
            string = item.transformed

        regexiter = self.regex.finditer(string)
        shortest = next(regexiter, None)

        if shortest is None:
            return FuzzyMatch.none

        shortest_length = len(shortest.groups()[0])
        pattern_length = self.length

        if shortest_length != pattern_length:
            for match in regexiter:
                match_length = len(match.groups()[0])

                if match_length < shortest_length:
                    shortest = match
                    shortest_length = match_length

                if match_length == pattern_length:
                    break

        return FuzzyMatch(shortest, self)


class FuzzyTerm(object):
    def __init__(self, item, *patterns):
        self.item = item
        self._matches = [pattern.find_shortest(item) for pattern in patterns]

    def matched(self):
        for match in self._matches:
            if not match:
                return False
        return True

    @property
    def rank(self):
        length = len(self.item.transformed)

        def rank_for(match):
            if match.pattern_length == 0:
                return length
            return len(match) * length / match.pattern_length

        return sum(rank_for(match) for match in self._matches)

    @property
    def value(self):
        return self.item.value

    @property
    def highlight(self):
        chunks = []

        match = functools.reduce(lambda acc, m: acc.merge(m), self._matches)

        for start, end in match:
            chunks.append(dict(
                beginning=self.value[:start],
                middle=self.value[start:end],
                ending=self.value[end:]
            ))

        return chunks


class Search(object):
    def __init__(self, factory, transform, limit):
        self.factory = factory
        self.transform = transform
        self.limit = limit

    def matches(self, items):
        f = self.factory
        terms = (f(i) for i in self.transform(items) if i.value)
        return (SearchResult(term) for term in sorted(
            (term for term in terms if term.matched()),
            key=operator.attrgetter('rank')
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
    return (Item(i, i.split('\t')[0]) for i in items)


def _until_last_tab_transform(items):
    return (Item(
        i,
        '\t'.join(i.split('\t')[:-1]).strip('\t') if '\t' in i else i
    ) for i in items)


def filter(items, pat, limit, mmode, ispath, crfile, isregex):
    limit = int(limit)
    ispath = int(ispath)
    isregex = int(isregex)

    if isregex:
        pattern = re.compile('(?iu)' + pat if pat else '.*')
        factory = lambda i: RegexTerm(pat, pattern, i)
    else:
        it = iter(pat.lstrip())
        c = next(it, None)

        patterns = [[]]
        pattern, = patterns

        # Pattern separation.
        #
        # Multiple patterns can be entered by separating them with ` `
        # (spaces).  A hard space is entered with `\ `.  The `\` has special
        # meaning, since it is used to escape hard spaces.  So `\\` means `\`
        # while `\ ` means ` `.
        #
        # We need to consume each char and test them, instead of trying to be
        # smart and do search and replace.  The following must hold:
        #
        # 1. `\\ ` translates to `\ `, but the whitespace is not escaped
        #    because its preceding `\` is the result of a previous escape (so
        #    this breaks the pattern).
        #
        # 2. `\\\ ` translates to `\ `, but there are two escapes: one for the
        #    `\` and other for the ` ` (so this is a hard space and will not
        #    lead to a break in the pattern).
        #
        # And so on; escapes must be interpreted in the order they occur, from
        # left to right.
        #
        # I couldn't figure out a way of doing this with search and replace
        # without temporarily replacing one string with a possibly unique
        # sequence and later replacing it again (but this is weak).
        while c is not None:
            if c == '\\':
                pattern.append(next(it, '\\'))
            elif c == ' ':
                pattern = []
                patterns.append(pattern)
            else:
                pattern.append(c)
            c = next(it, None)

        patterns = [FuzzyPattern(''.join(p)) for p in patterns]
        factory = lambda i: FuzzyTerm(i, *patterns)

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
        current_file = ''
        is_path = False

    input_lines = (line.strip() for line in sys.stdin.readlines())

    if not PY3:
        pattern = pattern.decode(CHARSET)
        current_file = current_file.decode(CHARSET)
        input_lines = (line.decode(CHARSET) for line in input_lines)

    results = filter_ctrlp_list(
        input_lines,
        pattern,
        args.limit if args.limit > 0 else 1,
        match_mode,
        is_path,
        current_file,
        is_regex
    )

    sys.stdout.write('\n'.join(result['value'].decode(CHARSET)
                               for result in results))
    sys.stdout.write('\n')
    sys.stdout.flush()


if HAS_VIM_BRIDGE:
    try:
        filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
    except ImportError:
        # Vim Bridge tries to import vim during the call to bridge().
        pass
