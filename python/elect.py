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

    def translate_merging(self, spans):
        translation = []
        last_end = 0

        for start, end in sorted(spans):
            translation.append(dict(
                nohl=self.original_value[last_end:start],
                hl=self.original_value[start:end]
            ))
            last_end = end

        translation.append(dict(
            nohl=self.original_value[last_end:],
            hl=''
        ))

        return translation


class RegexTerm(object):
    def __init__(self, entry, *patterns):
        self.entry = entry
        self._matches = []
        self.matched = False
        self.rank = 0

        value = entry.value
        if patterns:
            for pattern in patterns:
                m = pattern.search(value)

                if m is None:
                    self.rank = float('+inf')
                    return

                self._matches.append(m)
                start, end = m.span()
                self.rank += 1 - (end - start) / len(value)

            self.matched = True
        else:
            self.rank = 1 / len(value)
            self.matched = True

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
        if self.pattern.ignore_case:
            string = string.lower()

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
        self.indices = set(indices)

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

        if pattern_lower:
            if pattern_lower != pattern:
                input = self.pattern = pattern
                self.ignore_case = ignore_case = False
            else:
                input = self.pattern = pattern_lower
                self.ignore_case = ignore_case = True

            self.length = len(input)

            self._finditer = re.compile(
                '(?%(flags)su)(?=(%(cooked)s))' % dict(
                    flags='i' if ignore_case else '',
                    cooked=re.escape(input[0]) + ''.join(
                        '[^%(c)s]*?%(c)s' % {'c': re.escape(c)}
                        for c in input[1:]
                    )
                )
            ).finditer
        else:
            self.length = 0
            self.best_match = FuzzyMatch.unhighlighted

    def __len__(self):
        return self.length

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    def best_match(self, entry):
        regexiter = self._finditer(entry.value)
        shortest = next(regexiter, None)

        if shortest is None:
            return

        shortest = FuzzyMatch(shortest, self)

        for match in regexiter:
            match = FuzzyMatch(match, self)
            if match.distance < shortest.distance:
                shortest = match
                if shortest.distance == 1:
                    break

        return shortest


class NegativeFuzzyPattern(object):
    def __init__(self, pattern):
        pattern_lower = pattern.lower()

        if pattern_lower:
            if pattern_lower != pattern:
                input = self.pattern = pattern
                self.ignore_case = False
            else:
                input = self.pattern = pattern_lower
                self.ignore_case = True

            self.length = len(input)
        else:
            self.length = 0
            self.best_match = FuzzyMatch.unhighlighted

    def __len__(self):
        return self.length

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    def best_match(self, entry):
        if entry.value.find(self.pattern) != -1:
            return
        return FuzzyMatch.unhighlighted(entry)


class FuzzyTerm(object):
    def __init__(self, entry, *patterns):
        self.entry = entry
        self._matches = []
        self.matched = False

        for pattern in patterns:
            m = pattern.best_match(entry)
            if not m:
                return
            self._matches.append(m)

        self.matched = True

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
    def __init__(self, term_factory, *patterns):
        self.term_factory = term_factory
        self.patterns = patterns

    def elect(self, candidates, limit=None, transform=Entry):
        sorted_terms = sorted(self._process_terms(candidates, transform),
                              key=operator.attrgetter('rank'))
        if limit is not None:
            sorted_terms = sorted_terms[:limit]

        return (Result(term) for term in sorted_terms)

    def _process_terms(self, candidates, transform):
        f = self.term_factory
        patterns = self.patterns

        return (
            term
            for term in (f(transform(c), *patterns) for c in candidates if c)
            if term.matched
        )


class Result(object):
    def __init__(self, term):
        self.term = term
        self.entry = term.entry
        self.original_value = term.entry.original_value

    def asdict(self):
        return dict(value=self.entry.value,
                    original_value=self.original_value,
                    spans=self.spans,
                    merged_spans=self.entry.translate_merging(self.term.spans))

    @property
    def spans(self):
        return self.entry.translate(self.term.spans)


def filter_re(candidates, *patterns, **options):
    return Contest(
        RegexTerm,
        *[re.compile('(?iu)' + pattern) for pattern in patterns if pattern]
    ).elect(candidates, **options)


def make_fuzzy_pattern(pattern):
    if pattern.startswith('!'):
        return NegativeFuzzyPattern(pattern[1:])
    return FuzzyPattern(pattern)


def filter_fuzzy(candidates, *patterns, **options):
    return Contest(
        FuzzyTerm,
        *[make_fuzzy_pattern(''.join(p)) for p in patterns]
    ).elect(candidates, **options)


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

    if algorithm == 're':
        filter = filter_re
    elif algorithm == 'fuzzy':
        filter = filter_fuzzy
    else:
        raise ValueError("Unknown algorithm: %r" % algorithm)

    results = filter(
        entries,
        limit=limit,
        *patterns
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
