from __future__ import unicode_literals

import elect
import os.path

CHARSET = 'utf-8'


class FilenameEntry(elect.Entry):
    def __init__(self, value):
        self.original_value = value
        self.value = os.path.basename(value)

    def translate(self, spans):
        offset = len(self.original_value) - len(self.value)
        spans = ((start + offset, end + offset) for start, end in spans)
        return super(FilenameEntry, self).translate(spans)


class FirstNonTab(elect.Entry):
    def __init__(self, value):
        self.original_value = value
        self.value = value.split('\t')[0]


class UntilLastTabTransform(elect.Entry):
    def __init__(self, v):
        self.original_value = v
        self.value = \
            '\t'.join(v.split('\t')[:-1]).strip('\t') if '\t' in v else v


def filter(items, pat, limit, mmode, isregex):
    limit = int(limit)
    isregex = int(isregex)

    if isregex:
        filter = elect.filter_re
        patterns = [pat]
    elif ' ' not in pat and '\\' not in pat:
        # Optimization for the common case of a single pattern:  Don't parse
        # it, since it doesn't contain any special character.
        filter = elect.filter_fuzzy
        patterns = [pat]
    else:
        filter = elect.filter_fuzzy
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

    transform = dict(
        fullline=elect.Entry,
        filenameonly=FilenameEntry,
        firstnontab=FirstNonTab,
        untillasttab=UntilLastTabTransform,
    )[mmode.replace('-', '')]

    return filter(items, limit=limit, transform=transform, *patterns)
