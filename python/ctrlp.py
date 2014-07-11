from __future__ import division
from __future__ import unicode_literals

import elect
import os.path
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


def cached(fn):
    cached_name = '_' + fn.__name__

    def cached(self):
        if getattr(self, cached_name, None) is None:
            setattr(self, cached_name, fn())
        return getattr(self, cached_name)

    return cached


class ComputedEntry(elect.Entry):
    _value = None

    @cached
    def value(self):
        return self._compute_value()


class FilenameEntry(ComputedEntry):
    @cached
    def value(self):
        return os.path.basename(self.original_value)

    def translate(self, spans):
        offset = len(self.original_value) - len(self.value)
        spans = ((start + offset, end + offset) for start, end in spans)
        return super(FilenameEntry, self).translate(spans)


class FirstNonTab(ComputedEntry):
    @cached
    def value(self):
        return self.original_value.split('\t')[0]


class UntilLastTabTransform(ComputedEntry):
    @cached
    def value(self):
        v = self.original_value
        return '\t'.join(v.split('\t')[:-1]).strip('\t') if '\t' in v else v


def _filter(items, pat, limit, mmode, isregex):
    limit = int(limit)
    isregex = int(isregex)

    if isregex:
        algorithm = 're'
        patterns = [pat]
    else:
        algorithm = 'fuzzy'
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

    return elect.filter(algorithm, items, patterns, limit, transform)


def filter_ctrlp_list(items, pat, limit, mmode, isregex):
    try:
        return [
            result.asdict()
            for result in _filter(items, pat, limit, mmode, isregex)
        ]
    except Exception:
        if __name__ == '__main__':
            raise

        import traceback
        return list(reversed(
            dict(highlight=[], value=line.encode(CHARSET))
            for line in traceback.format_exception(*sys.exc_info())
        ))


if HAS_VIM_BRIDGE:
    try:
        filter_ctrlp_list = vim_bridge.bridged(filter_ctrlp_list)
    except ImportError:
        # Vim Bridge tries to import vim during the call to bridge().
        pass
