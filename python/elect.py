"""Elect.

Usage:
    elect [options] ALGORITHM PATTERN ...

Filter lines from standard input according to one or more patterns, and print
them to standard output.

Results are sorted by length of matched portion (average for more than one
pattern), followed by length of item.


Arguments:
    ALGORITHM  The algorithm to use (also affects how pattern is interpreted).
               `re' will treat PATTERNs as regular expressions, while `fuzzy'
               will treat them as fuzzy substrings.
    PATTERN    The pattern string (there can be multiple ones).


Options:
    -h, --help     Show this.

    -l LIMIT, --limit=LIMIT
                   Limit output up to LIMIT results.

    --sort-limit=LIMIT
                   Sort output only if the number of results is below LIMIT.
                   Set to zero to not sort the output.  Negative numbers are
                   silently ignored, as if there were no limit.  There's no
                   default value, so output is always sorted by default.

    -r, --reverse  Reverse the returning order of candidates.

    --ignore-bad-patterns
                   If a regular expression pattern is not valid, silently
                   ignore it.  It's used only if the algorithm is `re'.

    -d --debug     Print additional information to STDERR.
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


def debug(fn):
    sys.stderr.write(fn() + "\n")


class Term(object):
    matched = False

    def __init__(self, original_value, value, patterns):
        self.original_value = original_value
        self.value = value

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


class RegexTerm(Term):
    def __init__(self, original_value, value, patterns):
        super(RegexTerm, self).__init__(original_value, value, patterns)

        self._matches = []
        self.rank = 0

        value = self.value
        l = len(value)
        if not patterns:
            self.rank = l
            self.matched = True
            return

        matches = [m for m in (pattern.search(value) for pattern in patterns)
                   if m is not None]

        if len(matches) < len(patterns):
            return

        self._matches = matches
        self.rank += sum(
            (end - start) * 10000 + l
            for start, end in (m.span() for m in matches)
        )
        self.matched = True

    def spans(self):
        current_span = []
        spans = [current_span]

        overlaps = lambda s1, s2: s1[0] <= s2[1] and s2[0] <= s1[1]

        for match in self._matches:
            start, end = match.span()

            if not current_span:
                current_span.extend((start, end))
            elif overlaps((start, end), current_span):
                current_span[0] = min((current_span[0], start))
                current_span[1] = max((current_span[1], end))
            else:
                current_span = [start, end]
                spans.append(current_span)

        return (tuple(span) for span in spans if span)


class UnhighlightedFuzzyMatch(object):
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


class FuzzyMatch(object):
    def __init__(self, match, pattern):
        self.match = match
        self.pattern = pattern
        self.pattern_length = pattern.length
        self.length = len(match.groups()[0])

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
        self.value = pattern
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


class NegativeFuzzyPattern(object):
    def __init__(self, pattern):
        self.value = pattern
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

    def best_match(self, value):
        if value.find(self.pattern) != -1:
            return
        return FuzzyMatch.unhighlighted(value)


class FuzzyTerm(Term):
    def __init__(self, original_value, value, patterns):
        super(FuzzyTerm, self).__init__(original_value, value, patterns)

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
        l = len(self.value)
        return sum(m.length * 10000 + l for m in self._matches)

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

        return (Result(term) for term in terms)

    def _process_terms(self, candidates, transform):
        patterns = self.patterns
        factory = self.term_factory
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


def filter_re(candidates, *patterns, **options):
    re_patterns = []
    patterns = [p for p in patterns if p]
    ignore_bad_patterns = options.pop('ignore_bad_patterns', False)

    for pattern in patterns:
        try:
            regexp = re.compile('(?iu)' + pattern)
        except sre_constants.error:
            if not ignore_bad_patterns:
                raise
        else:
            re_patterns.append(regexp)

    return Contest(RegexTerm, *re_patterns).elect(candidates, **options)


def make_fuzzy_pattern(pattern):
    if pattern.startswith('!'):
        return NegativeFuzzyPattern(pattern[1:])
    return FuzzyPattern(pattern)


fuzzy_cache = {}


def filter_fuzzy(candidates, *patterns, **options):
    all_patterns = [make_fuzzy_pattern(''.join(p)) for p in patterns]
    contest = Contest(FuzzyTerm, *all_patterns)

    incremental = options.pop('incremental', False)
    negative_patterns = [
        p for p in all_patterns if isinstance(p, NegativeFuzzyPattern)
    ]

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
            from_cache = fuzzy_cache.get(p, None)
            if from_cache is not None:
                return (direct, p, from_cache)
            direct = False

        return (False, (), [])

    def update_candidates_from_cache(patterns, results):
        results = list(results)
        fuzzy_cache[tuple(patterns)] = results
        return results

    if options.get('debug', False):
        _debug = debug
    else:
        _debug = lambda f: None

    if all_patterns and incremental and not negative_patterns:
        pattern_set = tuple(p.value for p in all_patterns)
        direct, hit, results = candidates_from_cache(pattern_set)

        if hit:
            _debug(lambda: "cache: hit on {}\n".format(hit))
            _debug(lambda: "cache size: {}\n".format(len(results)))

            if direct:
                _debug(lambda: "using result directly from cache\n")
                return results

            results = contest.elect(
                [r.original_value for r in results],
                **options
            )
        else:
            _debug(lambda: "cache: miss, patterns: {}\n".format(pattern_set))
            results = contest.elect(candidates, **options)

        return update_candidates_from_cache(pattern_set, results)

    return contest.elect(candidates, **options)


def main():
    from docopt import docopt

    args = docopt(__doc__)

    patterns = args['PATTERN']
    algorithm = args['ALGORITHM']
    limit = args['--limit']
    sort_limit = args['--sort-limit']
    options = {}

    if algorithm not in ('re', 'fuzzy'):
        exit('Unknown algorithm: %r' % algorithm)

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

    if algorithm == 're':
        f = filter_re
    elif algorithm == 'fuzzy':
        f = filter_fuzzy
    else:
        raise ValueError("Unknown algorithm: %r" % algorithm)

    results = f(entries, *patterns, **options)

    if args['--reverse']:
        results = reversed(results)

    sys.stdout.write(
        u'\n'.join(result.original_value for result in results)
    )

    sys.stdout.write(u'\n')
    sys.stdout.flush()

    return 0

if __name__ == '__main__':
    sys.exit(main())
