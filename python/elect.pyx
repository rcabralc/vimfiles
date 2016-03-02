# cython: profile=True
"""Elect.

Usage:
    elect [options] PATTERNS ...

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
    PATTERNS   The pattern string (there can be multiple ones).

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

        Each line is a JSON object representing the result of a matching entry
        in the input, containing the following properties:

        value   The raw entry.

        id      The id associated with the entry.

        partitions
                An array of JSON objects, with properties "unmatched" and
                "matched".  By concatenating these properties in this order,
                and concatenating the result of doing the same for each element
                in order, the entry (the value property) is recovered.

        rank    An array of two elements representing the quality of the match.
                Lower numbers are better.  The first number is the sum of
                extents of matched portions of the string of all patterns, and
                the second is the length of the entry.

    --source-command=COMMAND
        Instead of taking items from standard input, take them from the output
        of COMMAND.

        Any '%s' in the COMMAND string is replaced by the raw patterns (in
        order).

        This option, in conjunction with `--source-match-start',
        `--source-match-end' and `--output-json', make this script work as a
        generic normalizing transformer for arbitrary commands.

    --source-match-start=REGEXP
    --source-match-end=REGEXP
        Match start and end of matched portions in source lines accoding to the
        given REGEXPs.

        Usually they should match the escapes \\x1b[31m and \\x1b[9m,
        respectively.  There's no default.

        They should be given together.  If one of them is given and not the
        other, the script terminates with an error code, and no output is
        printed.

        Once they are both given, the script will behave as a normalizing
        transformer on the items of standard input (or whatever is used in
        `--source-command'), and no filtering or sorting is done (all patterns
        are ignored, unless they are being passed to the source command).  If
        `--entry' regular expression is provided, its result is the one used to
        find match starts and ends.

        If `--output-json' is given, the rank property will be [0, 0] for all
        objects, since no sorting or filtering is done.

    --id=REGEXP
        Run input lines through REGEXP in order to extract an id.

        By default, the id of a term is its 1-based line number.  Using ids
        make them trackable from outside.  Ids and entries are emitted in the
        output in the format given in `--output'.

    --entry=REGEXP
        Run input lines through REGEXP in order to extract the entry's value.

        By default, this is the whole line.

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

    def __bool__(self):
        return self.length > 0

    __nonzero__ = __bool__


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


cdef class FuzzyPattern(object):
    cdef readonly int ignore_case
    cdef readonly int incremental
    cdef readonly int length
    cdef readonly object value
    cdef readonly object _finditer

    def __cinit__(self, pattern):
        self.incremental = True
        pattern_lower = pattern.lower()

        if pattern_lower != pattern:
            self.value = pattern
            self.ignore_case = False
        else:
            self.value = pattern_lower
            self.ignore_case = True

        if pattern:
            self.length = len(pattern)
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
        else:
            self.length = 0

    cdef inline best_match(FuzzyPattern self, object value):
        cdef int length
        cdef FuzzyMatch shortest, match

        if self.length == 0:
            return UnhighlightedMatch(value)

        regexiter = self._finditer(value)
        shortest_re_match = next(regexiter, None)

        if shortest_re_match is None:
            return None

        length = self.length
        shortest = FuzzyMatch(shortest_re_match, self)

        if shortest.length == length:
            return shortest

        for re_match in regexiter:
            match = FuzzyMatch(re_match, self)
            if match.length >= shortest.length:
                continue
            if match.length == length:
                return match
            shortest = match

        return shortest

    def __bool__(self):
        return self.length > 0

    __nonzero__ = __bool__

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


cdef class CompositePattern(object):
    cdef readonly object _patterns

    def __cinit__(self, patterns):
        self._patterns = patterns

    cpdef match(self, Term term):
        matches = []

        for pattern in self._patterns:
            if pattern.__class__ is FuzzyPattern:
                best_match = FuzzyPattern.best_match(pattern, term.value)
            else:
                best_match = pattern.best_match(term.value)

            if not best_match:
                return None

            matches.append(best_match)

        return CompositeMatch(term, tuple(matches))


cdef class UnhighlightedMatch(object):
    __slots__ = ('length',)
    cdef readonly int length

    def __cinit__(self, value):
        self.length = len(value)

    def __bool__(self):
        return self.length > 0

    __nonzero__ = __bool__

    @property
    def indices(self):
        return frozenset()


class ExactMatch(object):
    __slots__ = ('_value', '_pattern', 'length')

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


cdef class FuzzyMatch(object):
    __slots__ = ('_match', '_pattern', 'length')
    cdef readonly object _match
    cdef readonly object _pattern
    cdef readonly int length

    def __cinit__(self, match, pattern):
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
    __slots__ = ('_match', 'length', 'indices')

    def __init__(self, match):
        self._match = match
        start, end = match.span()
        self.length = end - start
        self.indices = range(start, end)


class Streaks(object):
    def __init__(self, indices):
        self.indices = frozenset(indices)

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


cdef class CompositeMatch(object):
    __slots__ = ('id', 'value', 'term', 'rank', '_matches')
    cdef readonly object id
    cdef readonly object value
    cdef readonly object term
    cdef readonly object rank
    cdef readonly object _matches

    def __cinit__(self, term, matches):
        self.id = term.id
        self.value = term.value
        self.term = term
        self.rank = (sum(m.length for m in matches), len(term.value))
        self._matches = matches

    def asdict(self):
        return dict(id=self.id, value=self.value,
                    rank=self.rank, partitions=self.partitions)

    @property
    def partitions(self):
        partitions = []
        last_end = 0
        value = self.value

        for start, end in sorted(self._spans()):
            partitions.append(dict(
                unmatched=value[last_end:start],
                matched=value[start:end]
            ))
            last_end = end

        remainder = value[last_end:]

        if remainder:
            partitions.append(dict(unmatched=remainder, matched=''))

        return partitions

    def _spans(self):
        streaks = functools.reduce(
            lambda acc, streaks: acc.merge(streaks),
            (Streaks(m.indices) for m in self._matches)
        )
        for start, end in streaks:
            yield (start, end)


cdef class Term(object):
    __slots__ = ('id', 'value')
    cdef readonly object id
    cdef readonly object value

    def __init__(self, id, value):
        self.id = id
        self.value = value


class Contest(object):
    def __init__(self, *patterns):
        self.pattern = CompositePattern(list(patterns))

    def elect(self, terms, **kw):
        match = self.pattern.match
        limit = kw.get('limit', None)
        sort_limit = kw.get('sort_limit', None)
        key = operator.attrgetter('rank')
        # `is not None' is faster and None is common, so sub-case it for perf.
        matches = (m for m in (match(t) for t in terms) if m is not None and m)

        if sort_limit is None:
            processed_matches = sorted(matches, key=key)
        elif sort_limit <= 0:
            processed_matches = matches
        else:
            processed_matches = list(matches)
            if len(processed_matches) < sort_limit:
                processed_matches = sorted(processed_matches, key=key)

        if limit is not None:
            processed_matches = list(processed_matches)[:limit]

        if kw.get('reverse', False):
            processed_matches = reversed(list(processed_matches))

        return processed_matches


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

    def update(self, patterns, matches, debug=False):
        if len(set(type(p) for p in patterns)) == 1:
            self._cache[type(patterns[0])].update(patterns, matches, debug=debug)

    def find(self, patterns, default=frozenset(), debug=False):
        for pattern in patterns:
            self._cache.setdefault(type(pattern), PatternTypeCache())

        best_patterns = set()
        matches = set()
        for t, best, cached in self._get_terms(patterns, default, debug):
            best_patterns.add((t, best))
            matches.update(cached)

        return (best_patterns, matches)

    def _get_terms(self, patterns, default, debug):
        for pattern_type, patterns in self._group_types(patterns):
            best_pattern, cached = self._cache[pattern_type].find(
                patterns, default=default, debug=debug
            )
            yield (pattern_type, best_pattern, cached)

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

    def update(self, patterns, matches, debug=False):
        if debug:
            debug = lambda fn: sys.stderr.write(fn())
        else:
            debug = lambda fn: None

        patterns = tuple(p.value for p in patterns)
        debug(lambda: "updating cache for patterns: {}\n".format(patterns))
        self._cache[patterns] = frozenset(matches)

    def find(self, patterns, default=frozenset(), debug=False):
        patterns = tuple(p.value for p in patterns)
        cached = None
        best_pattern = ()

        if debug:
            debug = lambda fn: sys.stderr.write(fn())
        else:
            debug = lambda fn: None

        for expansion in self._exhaust(patterns):
            debug(lambda: "attempting expansion: {}\n".format(expansion))
            from_cache = self._cache.get(expansion, None)

            if not from_cache:
                continue

            if cached is None or len(from_cache) < len(cached):
                debug(lambda: "cache: hit on {}\n".format(expansion))
                debug(lambda: "cache size: {}\n".format(len(from_cache)))
                best_pattern = expansion
                cached = from_cache
                break

        if cached is None:
            debug(lambda: "cache: miss, patterns: {}\n".format(patterns))
            return (frozenset(), default)

        if best_pattern == patterns:
            debug(lambda: "using result directly from cache\n")

        return (frozenset(best_pattern), cached)

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
        def best_possible_patterns(patterns):
            groups = {}

            for pattern in patterns:
                group = groups.setdefault(type(pattern), [])
                group.append(pattern)

            for t, patterns in groups.items():
                yield (t, frozenset(p.value for p in patterns))

        find = incremental_cache.find
        best_patterns, cached = find(patterns, debug=debug)

        if best_patterns == best_possible_patterns(patterns):
            return cached

        for type, best in best_patterns:
            if best:
                # There was at least one partial hit for one pattern, so
                # cached, even if empty, is the result of some previous
                # filtering.
                return full_filter(r.term for r in cached)

        # No hit for these patterns.
        return full_filter(terms)

    def update_candidates_from_cache(patterns, matches):
        incremental_cache.update(patterns, matches, debug=debug)
        return matches

    matches = candidates_from_cache(patterns)
    return update_candidates_from_cache(patterns, matches)


def build_line(result, highlight=True):
    line = []

    def colored(string):
        if not highlight or not string:
            return ''
        return "\x1b[1m\x1b[31m%s\x1b[22m\x1b[39m" % string

    line.append("\x1b[22m\x1b[39m")

    for partition in result.partitions:
        line.append(partition['unmatched'])
        line.append(colored(partition['matched']))

    return ''.join(line)


def main():
    from docopt import docopt
    from json import dumps as dumpjson

    args = docopt(__doc__)

    patterns = args['PATTERNS']
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
    terms = (Term(i, c) for i, c in enumerate(entries, start=1) if c)
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
