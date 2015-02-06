from __future__ import unicode_literals

import elect


def filter(items, pat, **options):
    algorithm = options.pop('algorithm', 'fuzzy')

    if algorithm == 're':
        filter = elect.filter_re
        options.setdefault('ignore_bad_patterns', True)
    else:
        filter = elect.filter_fuzzy

    if ' ' not in pat and '\\' not in pat:
        # Optimization for the common case of a single pattern:  Don't parse
        # it, since it doesn't contain any special character.
        patterns = [pat]
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

        patterns = [''.join(p) for p in patterns if p]

    return filter(items, *patterns, **options)
