"""Elect.

Usage:
    elect [options] PATTERN ...

Filter lines from standard input according to one or more patterns, and print
them to standard output.

Results are sorted by length of matched portion (average for more than one
pattern), followed by length of item.

Arguments:
    PATTERN    The pattern string (there can be multiple ones).

Options:
    -l LIMIT, --limit=LIMIT
        Limit output up to LIMIT results.

    --sort-limit=LIMIT
        Sort output only if the number of results is below LIMIT.  Set to zero
        to not sort the output.  Negative numbers are silently ignored, as if
        there were no limit.  There's no default value, so output is always
        sorted by default.

    -r, --reverse
        Reverse the returning order of candidates.

    --ignore-bad-patterns
        If a regular expression pattern is not valid, silently ignore it.

    -d --debug
        Print additional information to STDERR.

    -h, --help
        Show this.

Patterns:
    The interpretation of the pattern is done accordingly to its initial
    characters (which is not part of the pattern):

        @                   Regular expression.
        =                   Exact match.
        !=                  Exact inverse match.
        !                   Non-exact fuzzy inverse match.
        <anything else>     Fuzzy match.
"""

from __future__ import division
from __future__ import unicode_literals

import functools
import operator
import re
import sre_constants
import sys

try:
    unicode
    PY3 = False
except NameError:
    PY3 = True

CHARSET = 'utf-8'


class UnhighlightedMatch(object):
    length = 0

    def __init__(self, value):
        self.length = len(value)

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0

    @property
    def indices(self):
        return frozenset()


class ExactMatch(object):
    def __init__(self, value, pattern):
        self._value = value
        self._pattern = pattern
        self._pattern_length = self.length = pattern.length

    @property
    def indices(self):
        indices = []

        string = self._value
        if self._pattern.ignore_case:
            string = string.lower()

        current = string.find(self._pattern.value)
        for index in range(current, current + self._pattern_length):
            indices.append(index)

        return frozenset(indices)


class FuzzyMatch(object):
    def __init__(self, match, pattern):
        self._match = match
        self._pattern = pattern
        self._pattern_length = pattern.length
        self.length = len(match.groups()[0])

    @property
    def indices(self):
        indices = []

        string = self._match.string
        if self._pattern.ignore_case:
            string = string.lower()

        pattern = self._pattern.value
        pattern_length = self._pattern_length
        current = self._match.start()
        pos = 0

        find = string.find

        while pos < pattern_length:
            current = find(pattern[pos], current)
            indices.append(current)
            pos += 1
            current += 1

        return frozenset(indices)


class RegexMatch(object):
    def __init__(self, match):
        self._match = match
        start, end = match.span()
        self.length = end - start
        self.indices = range(start, end)


class Streaks(object):
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


class Pattern(object):
    incremental = False

    def __init__(self, pattern):
        self.value = pattern

        if pattern:
            self.length = len(pattern)
        else:
            self.length = 0
            self.best_match = UnhighlightedMatch

    def __len__(self):
        return self.length

    def __nonzero__(self):
        return self.__bool__()

    def __bool__(self):
        return self.length > 0


class SmartCasePattern(Pattern):
    def __init__(self, pattern):
        super(SmartCasePattern, self).__init__(pattern)

        pattern_lower = pattern.lower()

        if pattern_lower != pattern:
            self.value = pattern
            self.ignore_case = False
        else:
            self.value = pattern_lower
            self.ignore_case = True


class ExactPattern(SmartCasePattern):
    incremental = True

    def best_match(self, value):
        if self.ignore_case:
            value = value.lower()

        if self.value not in value:
            return

        return ExactMatch(value, self)


class FuzzyPattern(SmartCasePattern):
    incremental = True

    def __init__(self, pattern):
        super(FuzzyPattern, self).__init__(pattern)

        if self.length > 0:
            input = self.value

            self._finditer = re.compile(
                '(?%(flags)su)(?=(%(cooked)s))' % dict(
                    flags='i' if self.ignore_case else '',
                    cooked=re.escape(input[0]) + ''.join(
                        '[^%(c)s]*?%(c)s' % {'c': re.escape(c)}
                        for c in input[1:]
                    )
                )
            ).finditer

    def best_match(self, value):
        regexiter = self._finditer(value)
        shortest = next(regexiter, None)
        length = self.length

        if shortest is None:
            return

        shortest = FuzzyMatch(shortest, self)

        for match in regexiter:
            match = FuzzyMatch(match, self)
            if match.length < shortest.length:
                shortest = match
                if shortest.length == length:
                    break

        return shortest


class InverseFuzzyPattern(FuzzyPattern):
    def best_match(self, value):
        if next(self._finditer(value), None):
            return
        return UnhighlightedMatch(value)


class InverseExactPattern(ExactPattern):
    def best_match(self, value):
        if self.ignore_case:
            value = value.lower()

        if self.value in value:
            return

        return UnhighlightedMatch(value)


class RegexPattern(Pattern):
    def __init__(self, pattern, ignore_bad_patterns=False):
        if not pattern:
            self.best_match = UnhighlightedMatch
        else:
            try:
                self._re = re.compile('(?iu)' + pattern)
            except sre_constants.error:
                if not ignore_bad_patterns:
                    raise
                self.best_match = UnhighlightedMatch

    def best_match(self, value):
        match = self._re.search(value)
        if match is not None:
            return RegexMatch(match)


class Term(object):
    matched = False

    def __init__(self, original_value, value, patterns):
        self.original_value = original_value
        self.value = value
        self._matches = []
        for pattern in patterns:
            m = pattern.best_match(value)
            if not m:
                break
            self._matches.append(m)
        else:
            self.matched = True

    @property
    def rank(self):
        if getattr(self, '_rank', None) is not None:
            return self._rank

        if not self.matched:
            rank = float('+inf')
        elif not self.value:
            rank = len(self.value)
        else:
            l = len(self.value)
            rank = sum(m.length * 10000 + l for m in self._matches)

        self._rank = rank
        return self._rank

    def spans(self):
        streaks = functools.reduce(
            lambda acc, streaks: acc.merge(streaks),
            (Streaks(m.indices) for m in self._matches)
        )
        for start, end in streaks:
            yield (start, end)

    def translate(self):
        translation = []

        for start, end in self.spans():
            translation.append(dict(
                beginning=self.original_value[:start],
                middle=self.original_value[start:end],
                ending=self.original_value[end:]
            ))

        return translation

    def translate_merging(self):
        translation = []
        last_end = 0

        for start, end in sorted(self.spans()):
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


class Contest(object):
    def __init__(self, *patterns):
        self.patterns = patterns

    def elect(self, candidates, **kw):
        limit = kw.get('limit', None)
        transform = kw.get('transform', None)
        sort_limit = kw.get('sort_limit', -1)
        key = operator.attrgetter('rank')

        if sort_limit < 0:
            terms = sorted(self._process_terms(candidates, transform), key=key)
        else:
            terms = list(self._process_terms(candidates, transform))
            if len(terms) < sort_limit:
                terms = sorted(terms, key=key)

        if limit is not None:
            terms = terms[:limit]

        result_factory = Result
        return (result_factory(term) for term in terms)

    def _process_terms(self, candidates, transform):
        patterns = self.patterns
        factory = Term
        entries = (c for c in candidates if c)

        if transform:
            f = lambda v, _, pats: factory(v, transform(v), patterns)
        else:
            f = factory

        return (
            term for term in (f(e, e, patterns) for e in entries)
            if term.matched
        )


class Result(object):
    def __init__(self, term):
        self.term = term

    @property
    def original_value(self):
        return self.term.original_value

    def asdict(self):
        return dict(value=self.term.value,
                    original_value=self.term.original_value,
                    spans=self.term.translate(),
                    merged_spans=self.term.translate_merging())


def make_pattern(pattern, ignore_bad_re_patterns=False):
    if pattern.startswith("!="):
        return InverseExactPattern(pattern[2:])
    elif pattern.startswith('!'):
        return InverseFuzzyPattern(pattern[1:])
    elif pattern.startswith("="):
        return ExactPattern(pattern[1:])
    elif pattern.startswith("@"):
        return RegexPattern(pattern[1:],
                            ignore_bad_patterns=ignore_bad_re_patterns)
    return FuzzyPattern(pattern)


incremental_cache = {}


def filter_entries(candidates, *patterns, **options):
    ignore_bad_patterns = options.pop('ignore_bad_patterns', False)

    patterns = [
        make_pattern(''.join(p), ignore_bad_re_patterns=ignore_bad_patterns)
        for p in patterns
    ]
    contest = Contest(*patterns)

    def full_filter(items):
        return contest.elect(items, **options)

    incremental = options.pop('incremental', False)
    debug = options.get('debug', False)

    if incremental:
        return incremental_filter(candidates, patterns, full_filter,
                                  debug=debug)
    else:
        return full_filter(candidates)


def incremental_filter(candidates, patterns, full_filter, debug=False):
    non_incremental_patterns = [p for p in patterns if not p.incremental]
    if non_incremental_patterns or not patterns:
        return full_filter(candidates)

    if debug:
        debug = lambda fn: sys.stderr.write(fn())
    else:
        debug = lambda fn: None

    def candidates_from_cache(patterns):
        def broaden(patterns):
            patterns[-1] = patterns[-1][:-1]

            if not patterns[-1]:
                return patterns[:-1]

            return patterns

        def possibilities(patterns):
            if not patterns:
                return

            yield tuple(patterns)
            for patterns in possibilities(broaden(list(patterns))):
                yield patterns

        direct = True
        for p in possibilities(patterns):
            from_cache = incremental_cache.get(p, None)
            if from_cache is not None:
                return (direct, p, from_cache)
            direct = False

        return (False, (), [])

    def update_candidates_from_cache(pattern_values, results):
        results = list(results)
        incremental_cache[tuple(pattern_values)] = results
        return results

    pattern_values = tuple(p.value for p in patterns)
    direct, hit, results = candidates_from_cache(pattern_values)

    if hit:
        debug(lambda: "cache: hit on {}\n".format(hit))
        debug(lambda: "cache size: {}\n".format(len(results)))

        if direct:
            debug(lambda: "using result directly from cache\n")
            return results

        results = full_filter([r.original_value for r in results])
    else:
        debug(lambda: "cache: miss, patterns: {}\n".format(pattern_values))
        results = full_filter(candidates)

    return update_candidates_from_cache(pattern_values, results)


def main():
    from docopt import docopt

    args = docopt(__doc__)

    patterns = args['PATTERN']
    limit = args['--limit']
    sort_limit = args['--sort-limit']
    options = {}

    if limit is not False and limit is not None:
        options['limit'] = int(limit)

    if sort_limit is not False and sort_limit is not None:
        options['sort_limit'] = int(sort_limit)

    if args['--ignore-bad-patterns']:
        options['ignore_bad_patterns'] = True

    if args['--debug']:
        options['debug'] = True

    strip = str.strip
    entries = (strip(line) for line in sys.stdin.readlines())

    if not PY3:
        patterns = [p.decode(CHARSET) for p in patterns]
        entries = (line.decode(CHARSET) for line in entries)

    results = filter_entries(entries, *patterns, **options)

    if args['--reverse']:
        results = reversed(results)

    if args['--debug']:
        sys.stdout.write(
            u'\n'.join(repr(result.asdict()) for result in results)
        )
    else:
        sys.stdout.write(
            u'\n'.join(result.original_value for result in results)
        )

    sys.stdout.write(u'\n')
    sys.stdout.flush()

    return 0

if __name__ == '__main__':
    sys.exit(main())
