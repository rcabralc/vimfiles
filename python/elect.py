"""Elect.

Usage:
    elect [options] PATTERN ...

Filter lines from standard input according to one or more patterns, and print
them to standard output.

Results are sorted by length of matched portion (sum for more than one
pattern), followed by length of item.

Depending on the given options, the output may or may not be printed as the
input is read.  If sorting is being done (the default) or some limit is
imposed, then the input will be fully read before processing candidates takes
place.  So, to use this as a stream filter, disable sorting, don't apply a
limit and don't reverse the order of the candidates.

Arguments:
    PATTERN    The pattern string (there can be multiple ones).

Options:
    -l LIMIT, --limit=LIMIT
        Limit output up to LIMIT results.  Makes input to be fully read before
        processing.

    --sort-limit=LIMIT
        Sort output only if the number of results is below LIMIT.  Set to zero
        to not sort the output.  Negative numbers are silently ignored, as if
        there were no limit.  There's no default value, so output is always
        sorted by default.

        If this option is not set or is set to a value greater than zero, input
        will be fully read before processing.

        Negative values are interpreted as zero.

    -r, --reverse
        Reverse the returning order of candidates.  Makes input to be fully
        read before processing.

        This is applied after sorting and limiting is done, so this affects
        only the output of the items, not the sorting itself.  If no sorting or
        limiting is done, all candidates are returned in the reversed order of
        input.

    --ignore-bad-patterns
        If a regular expression pattern is not valid, silently ignore it.

    -d --debug
        Print additional information to STDERR.

    --output-json
        Print lines as JSON objects.

    --no-color
        Turn off colored output.

    -h, --help
        Show this.

Patterns:
    The interpretation of the pattern is done according to its initial
    characters (which is not part of the pattern):

        @                   Regular expression.
        =                   Exact match.
        !=                  Exact inverse match.
        !                   Non-exact fuzzy inverse match.
        <anything else>     Fuzzy match.
"""

from __future__ import print_function

import functools
import operator
import re
import sre_constants
import sys


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
        self.length = pattern.length

    @property
    def indices(self):
        indices = []

        string = self._value
        if self._pattern.ignore_case:
            string = string.lower()

        current = string.find(self._pattern.value)
        for index in range(current, current + self._pattern.length):
            indices.append(index)

        return frozenset(indices)


class FuzzyMatch(object):
    def __init__(self, match, pattern):
        self._match = match
        self._pattern = pattern
        self.length = len(match.groups()[0])

    @property
    def indices(self):
        indices = []

        string = self._match.string
        if self._pattern.ignore_case:
            string = string.lower()

        pattern = self._pattern.value
        pattern_length = self._pattern.length
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

        if shortest is None:
            return

        length = self.length
        shortest = FuzzyMatch(shortest, self)

        if shortest.length == length:
            return shortest

        for match in regexiter:
            match = FuzzyMatch(match, self)
            if match.length >= shortest.length:
                continue
            if match.length == length:
                return match
            shortest = match

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


class Patterns(object):
    def __init__(self, patterns):
        self._pattern_match = patterns.pop(0).best_match
        if patterns:
            self._next_match = Patterns(patterns).match
        else:
            self._next_match = EmptyPatterns().match

    def match(self, value):
        match = self._pattern_match(value)
        if match is None:
            return

        next_matches = self._next_match(value)
        if next_matches is None:
            return

        return (match,) + next_matches


class EmptyPatterns(object):
    def match(self, value):
        return ()


class Term(object):
    def __init__(self, index, value):
        self.index = index
        self.value = value

    def match(self, patterns):
        matches = patterns.match(self.value)

        if matches is None:
            return False

        self._pattern_matches = matches
        self.rank = (sum(m.length for m in matches), len(self.value))
        return True

    def asdict(self):
        return dict(value=self.value,
                    index=self.index,
                    rank=self.rank,
                    matches=self.matches())

    def matches(self):
        translation = []
        last_end = 0
        value = self.value

        for start, end in sorted(self._spans()):
            translation.append(dict(
                unmatched=value[last_end:start],
                matched=value[start:end]
            ))
            last_end = end

        remainder = value[last_end:]

        if remainder:
            translation.append(dict(unmatched=remainder, matched=''))

        return translation

    def _spans(self):
        streaks = functools.reduce(
            lambda acc, streaks: acc.merge(streaks),
            (Streaks(m.indices) for m in self._pattern_matches)
        )
        for start, end in streaks:
            yield (start, end)


class Contest(object):
    def __init__(self, *patterns):
        self.patterns = Patterns(list(patterns))

    def elect(self, terms, **kw):
        patterns = self.patterns
        limit = kw.get('limit', None)
        sort_limit = kw.get('sort_limit', None)
        key = operator.attrgetter('rank')
        filtered_terms = (term for term in terms if term.match(patterns))

        if sort_limit is None:
            processed_terms = sorted(filtered_terms, key=key)
        elif sort_limit <= 0:
            processed_terms = filtered_terms
        else:
            processed_terms = list(filtered_terms)
            if len(processed_terms) < sort_limit:
                processed_terms = sorted(processed_terms, key=key)

        if limit is not None:
            processed_terms = list(processed_terms)[:limit]

        if kw.get('reverse', False):
            processed_terms = reversed(list(processed_terms))

        return processed_terms


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


class IncrementalCache(object):
    def __init__(self):
        self._cache = {}

    def clear(self):
        self._cache.clear()

    def update(self, patterns, terms, debug=False):
        if len(set(type(p) for p in patterns)) == 1:
            self._cache[type(patterns[0])].update(patterns, terms, debug=debug)

    def find(self, patterns, default=frozenset(), debug=False):
        for pattern in patterns:
            self._cache.setdefault(type(pattern), PatternTypeCache())

        return functools.reduce(
            frozenset.union,
            self._get_terms(patterns, default, debug)
        )

    def _get_terms(self, patterns, default, debug):
        for pattern_type, patterns in self._group_types(patterns):
            yield self._cache[pattern_type].find(patterns, default=default,
                                                 debug=debug)

    def _group_types(self, patterns):
        groups = {}

        for pattern in patterns:
            group = groups.setdefault(type(pattern), [])
            group.append(pattern)

        for t, patterns in groups.items():
            yield (t, patterns)


incremental_cache = IncrementalCache()


class PatternTypeCache(object):
    def __init__(self):
        self._cache = {}

    def update(self, patterns, terms, debug=False):
        if debug:
            debug = lambda fn: sys.stderr.write(fn())
        else:
            debug = lambda fn: None

        patterns = tuple(p.value for p in patterns)
        debug(lambda: "updating cache for patterns: {}\n".format(patterns))
        self._cache[patterns] = frozenset(terms)

    def find(self, patterns, default=frozenset(), debug=False):
        patterns = tuple(p.value for p in patterns)
        terms = None
        best_match = ()

        if debug:
            debug = lambda fn: sys.stderr.write(fn())
        else:
            debug = lambda fn: None

        for expansion in self._exhaust(patterns):
            debug(lambda: "attempting expansion: {}\n".format(expansion))
            from_cache = self._cache.get(expansion, None)

            if not from_cache:
                continue

            if terms is None or len(from_cache) < len(terms):
                debug(lambda: "cache: hit on {}\n".format(expansion))
                debug(lambda: "cache size: {}\n".format(len(from_cache)))
                best_match = expansion
                terms = from_cache

        if terms is None:
            debug(lambda: "cache: miss, patterns: {}\n".format(patterns))
            return frozenset(default)

        if best_match == patterns:
            debug(lambda: "using result directly from cache\n")

        return terms

    def _exhaust(self, patterns):
        if len(patterns) == 1:
            for exhaustion in self._exhaust_pattern(patterns[0]):
                yield (exhaustion,)
            return

        for i in range(len(patterns) - 1, -1, -1):
            pattern = patterns[i]
            lpatterns = patterns[:i]
            rpatterns = patterns[i + 1:]

            for exhaustion in self._exhaust_pattern(pattern):
                for subexhaustion in self._exhaust(rpatterns):
                    yield lpatterns + (exhaustion,) + subexhaustion

    def _exhaust_pattern(self, pattern):
        for i in range(len(pattern) - 1, -1, -1):
            yield pattern[0:i + 1]


def filter_entries(terms, *patterns, **options):
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
        return incremental_filter(terms, patterns, full_filter, debug=debug)
    return full_filter(terms)


def incremental_filter(terms, patterns, full_filter, debug=False):
    non_incremental_patterns = [p for p in patterns if not p.incremental]
    if non_incremental_patterns or not patterns:
        return full_filter(terms)

    def candidates_from_cache(patterns):
        return incremental_cache.find(patterns, default=terms, debug=debug)

    def update_candidates_from_cache(patterns, results):
        incremental_cache.update(patterns, results, debug=debug)
        return results

    results = list(full_filter(candidates_from_cache(patterns)))
    return update_candidates_from_cache(patterns, results)


def build_line(result, highlight=True):
    line = []

    def colored(string):
        if not highlight or not string:
            return ''
        return "\x1b[1m\x1b[31m%s\x1b[22m\x1b[39m" % string

    line.append("\x1b[22m\x1b[39m")

    for portion in result.matches():
        line.append(portion['unmatched'])
        line.append(colored(portion['matched']))

    return ''.join(line)


def main():
    from docopt import docopt
    from json import dumps as dumpjson

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

    if args['--reverse']:
        options['reverse'] = True

    strip = str.strip
    entries = (strip(line) for line in iter(sys.stdin.readline, ''))
    terms = (Term(i, c) for i, c in enumerate(entries) if c)
    results = filter_entries(terms, *patterns, **options)

    for result in results:
        if args['--output-json']:
            line = dumpjson(result.asdict())
        else:
            line = build_line(result, highlight=not args['--no-color'])
        print(line)

    return 0

if __name__ == '__main__':
    sys.exit(main())
