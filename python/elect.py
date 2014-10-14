"""Elect.

Usage:
    elect [options] ALGORITHM PATTERN ...

Filter lines from standard input according to one or more patterns, and print
them to standard output.

The results are sorted by the sum of the length of the matched portion of the
item for each pattern, weighted by the length of the item.  Shorter matches
will tend to be returned before longer matches.


Arguments:
    ALGORITHM  The algorithm to use (also affects how pattern is interpreted).
               `re` will treat PATTERNs as regular expressions, while `fuzzy`
               will treat them as fuzzy substrings.
    PATTERN    The pattern string (there can be multiple ones).


Options:
    -h, --help               Show this.
    -l LIMIT, --limit=LIMIT  Limit output up to LIMIT results.
    -n, --negate             Selects results which don't match any PATTERN.  No
                             sorting is done, since there's no matched portion.
    -r, --reverse            Reverse the returning order of candidates.
    --asdict                 Output results as Python dictionaries.
"""

from __future__ import division
from __future__ import unicode_literals

import functools
import operator
import re
import sys

try:
    unicode
    PY3 = False
except NameError:
    PY3 = True

CHARSET = 'utf-8'


class Entry(object):
    _lower = None

    def __init__(self, value):
        self.value = value
        self.original_value = value

    @property
    def lower(self):
        if self._lower is None:
            self._lower = self.value.lower()
        return self._lower

    def translate(self, spans):
        translation = []

        for start, end in spans:
            translation.append(dict(
                beginning=self.original_value[:start],
                middle=self.original_value[start:end],
                ending=self.original_value[end:]
            ))

        return translation


class RegexTerm(object):
    def __init__(self, entry, *patterns):
        self.entry = entry
        self.value = entry.value
        self._matches = [p.search(self.value) for p in patterns]

        rank = 0
        for m in self._matches:
            if m is not None:
                start, end = m.span()
                rank += 1 - (end - start) / len(self.value)
            else:
                rank += 1
        self.rank = rank

    def matched(self):
        return bool(None not in self._matches)

    @property
    def spans(self):
        return (match.span() for match in self._matches)


class UnhighlightedFuzzyMatch(object):
    distance = 1

    def __init__(self, entry):
        self.length = len(entry.value)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    @property
    def indices(self):
        return frozenset()


class FuzzyMatch(object):
    def __init__(self, match, pattern):
        self.match = match
        self.pattern = pattern
        self.pattern_length = pattern.length
        length = len(match.groups()[0])
        self.distance = length / self.pattern_length

    @property
    def indices(self):
        indices = []

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

        return frozenset(indices)


FuzzyMatch.unhighlighted = UnhighlightedFuzzyMatch


class FuzzyIndices(object):
    def __init__(self, indices):
        self.indices = indices

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
        return type(self)(self.indices.union(other.indices))


class FuzzyPattern(object):
    def __init__(self, pattern):
        pattern_lower = pattern.lower()

        if pattern_lower != pattern:
            input = self.pattern = pattern
            self._ignore_case = False
        else:
            input = self.pattern = pattern_lower
            self._ignore_case = True

        self.head = input[0:1]
        if self.head:
            self.regex = re.compile(
                '(?u)(?=((%s)' % re.escape(self.head) +
                ''.join(
                    '[^%(c)s]*?(%(c)s)' % {'c': re.escape(c)}
                    for c in input[1:]
                ) + '))'
            )
        else:
            self.regex = re.compile('')

        self.length = len(input)
        if not input:
            self.find_shortest = FuzzyMatch.unhighlighted

    def __len__(self):
        return self.length

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    def find_shortest(self, entry):
        string = entry.lower if self._ignore_case else entry.value
        regexiter = self.regex.finditer(string)
        shortest = next(regexiter, None)

        if shortest is None:
            return

        shortest_length = len(shortest.groups()[0])
        pattern_length = self.length

        for match in regexiter:
            match_length = len(match.groups()[0])

            if match_length < shortest_length:
                shortest = match
                shortest_length = match_length

            if match_length == pattern_length:
                break

        return FuzzyMatch(shortest, self)


class FuzzyTerm(object):
    def __init__(self, entry, *patterns):
        self.entry = entry
        self._pattern_count = len(patterns)
        self._matches = tuple(
            m for m in (pattern.find_shortest(entry) for pattern in patterns)
            if m
        )

    def matched(self):
        return self._pattern_count == len(self._matches)

    @property
    def rank(self):
        length = len(self.entry.value)
        return sum(match.distance * length for match in self._matches)

    @property
    def value(self):
        return self.entry.value

    @property
    def spans(self):
        indiceses = functools.reduce(
            lambda acc, indices: acc.merge(indices),
            (FuzzyIndices(m.indices) for m in self._matches)
        )
        for start, end in indiceses:
            yield (start, end)


class Contest(object):
    def __init__(self, term_factory, transform):
        self.term_factory = term_factory
        self.transform = transform

    def elect(self, candidates, limit=None):
        f = self.term_factory
        transform = self.transform
        terms = (f(transform(c)) for c in candidates if c)

        sorted_terms = sorted(
            (term for term in terms if term.matched()),
            key=operator.attrgetter('rank')
        )
        if limit is not None:
            sorted_terms = sorted_terms[:limit]

        return (Result(term.entry, term) for term in sorted_terms)


class Result(object):
    def __init__(self, entry, term):
        self.entry = entry
        self.term = term
        self.original_value = entry.original_value

    def asdict(self):
        return dict(value=self.entry.value,
                    original_value=self.entry.original_value,
                    spans=self.entry.translate(self.term.spans))


def filter(algorithm, candidates, patterns, limit=None, transform=Entry):
    if algorithm == 're':
        patterns = [
            re.compile('(?iu)' + pattern if pattern else '.*')
            for pattern in patterns
        ]
        factory = lambda i: RegexTerm(i, *patterns)
    elif algorithm == 'fuzzy':
        patterns = [FuzzyPattern(''.join(p)) for p in patterns]
        factory = lambda i: FuzzyTerm(i, *patterns)
    else:
        raise ValueError("Unknown algorithm: %r" % algorithm)

    return Contest(factory, transform).elect(candidates, limit)


if __name__ == '__main__':
    from docopt import docopt

    args = docopt(__doc__)

    patterns = args['PATTERN']
    algorithm = args['ALGORITHM']
    limit = args['--limit']

    if algorithm not in ('re', 'fuzzy'):
        exit('Unknown algorithm: %r' % algorithm)

    if limit is not False and limit is not None:
        limit = int(limit)
    else:
        limit = None

    entries = (line.strip() for line in sys.stdin.readlines())

    if not PY3:
        patterns = [p.decode(CHARSET) for p in patterns]
        entries = (line.decode(CHARSET) for line in entries)

    results = filter(
        algorithm,
        entries,
        patterns,
        limit,
    )

    if args['--reverse']:
        results = reversed(results)

    if args['--asdict']:
        sys.stdout.write(
            u'\n'.join(str(result.asdict()) for result in results)
        )
    else:
        sys.stdout.write(
            u'\n'.join(result.original_value for result in results)
        )

    sys.stdout.write(u'\n')
    sys.stdout.flush()
