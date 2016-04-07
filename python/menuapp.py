from PyQt5.QtCore import QObject, pyqtSlot, pyqtSignal, Qt
from PyQt5.QtGui import QPalette
from PyQt5.QtWebKitWidgets import QWebView
from PyQt5.QtWidgets import QApplication

import elect
import json
import os
import sys


MAX_HISTORY_ENTRIES = 100

Term = elect.Term


def filter(terms, pat, **options):
    if ' ' not in pat and '\\' not in pat:
        # Optimization for the common case of a single pattern:  Don't parse
        # it, since it doesn't contain any special character.
        patterns = [pat]
    else:
        it = iter(pat.lstrip())
        c = next(it, None)

        patterns = [[]]
        pattern, = patterns

        # Pattern splitting.
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

    return incremental_filter(terms, patterns, **options)


class Pattern(object):
    incremental = False

    def __init__(self, value):
        self.value = value

    def __eq__(self, other):
        if hasattr(other, 'value'):
            return self.value == other.value

    def __hash__(self):
        return hash(self.value)


class InverseExactPattern(Pattern):
    pass


class InverseFuzzyPattern(Pattern):
    pass


class ExactPattern(Pattern):
    incremental = True


class RegexPattern(Pattern):
    pass


class FuzzyPattern(Pattern):
    incremental = True


def make_pattern(value):
    if value.startswith("!="):
        return InverseExactPattern(value)
    elif value.startswith('!'):
        return InverseFuzzyPattern(value)
    elif value.startswith("="):
        return ExactPattern(value)
    elif value.startswith("@"):
        return RegexPattern(value)
    return FuzzyPattern(value)


def incremental_filter(terms, pattern_values, debug=False, **options):
    patterns = [make_pattern(p) for p in pattern_values]

    def full_filter(items):
        return elect.filter_entries(items, *pattern_values, **options)

    non_incremental_patterns = [p for p in patterns if not p.incremental]
    if non_incremental_patterns or not patterns:
        return full_filter(terms)

    def candidates_from_cache(patterns):
        def best_possible_patterns(patterns):
            groups = {}

            for pattern in patterns:
                groups.setdefault(type(pattern), []).append(pattern)

            for t, patterns in groups.items():
                yield (t, frozenset(patterns))

        find = incremental_cache.find
        best_patterns, cached = find(patterns, debug=debug)

        if best_patterns == set(best_possible_patterns(patterns)):
            return cached

        for t, best in best_patterns:
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


class Mode:
    def __init__(self, name, prompt):
        self.name = name
        self.prompt = prompt


insert_mode = Mode('insert', '>')
history_mode = Mode('history', '<')


class Menu(QObject):
    selected = pyqtSignal(str)
    dismissed = pyqtSignal()

    def __init__(self):
        super(Menu, self).__init__()

        self.clear()
        self._mode_handler = ModeHandler(self)
        self._history_path = os.path.join(os.path.dirname(__file__),
                                          'history.json')

    def setup(self, items,
              input='', limit=None, sep=None, history_key=None,
              delimiters=[], accept_input=False, debug=False):
        self.clear()

        self._all_terms = [Term(i, c) for i, c in enumerate(items) if c]
        self._history = History(self._history_path, history_key)
        self._total_items = len(items)
        self._limit = limit
        self.completion_sep = sep
        self.word_delimiters = delimiters
        self._accept_input = accept_input
        self._debug = debug
        self._mode_handler.switch(insert_mode)
        self._frontend.set_input(input)
        self.input = input

        return self

    def clear(self):
        incremental_cache.clear()

        self._all_terms = []
        self._index = 0
        self._history = None
        self._total_items = 0
        self._limit = None
        self.completion_sep = None
        self.word_delimiters = []
        self._accept_input = False
        self._debug = False
        self._input = None
        self._results = []

    def connect(self, frontend):
        self._frontend = frontend
        self._mode_handler.frontend = frontend

    def accept(self):
        selected = self.get_selected()
        if selected:
            self._history.add(self.input)
            self.selected.emit(selected)

    def accept_input(self):
        if self._accept_input:
            self._history.add(self.input)
            self.selected.emit(self.input)

    def enter(self, input):
        self.input = input
        self._mode_handler.switch(insert_mode)

    def next(self):
        self._index = min(self._index + 1, len(self.results) - 1)
        self._frontend.select(self._index)

    def prev(self):
        self._index = max(self._index - 1, 0)
        self._frontend.select(self._index)

    def history_next(self):
        entry = self._history.next(self._mode_handler.input)
        self._mode_handler.switch(history_mode)
        return (entry if entry else self._mode_handler.input)

    def history_prev(self):
        entry = self._history.prev(self._mode_handler.input)
        self._mode_handler.switch(history_mode)
        return (entry if entry else self._mode_handler.input)

    def complete(self):
        self._mode_handler.switch(insert_mode)
        candidates = self._candidates_for_completion()

        if len(candidates) == 0:
            return self.input

        if len(candidates) == 1:
            return candidates.pop()

        possible_candidates = candidates
        minlen = min(len(i) for i in candidates)
        for l in reversed(range(minlen)):
            possible_candidates = {i[:l + 1] for i in possible_candidates}
            if len(possible_candidates) == 1:
                return possible_candidates.pop()[:l + 1]

        return self.input

    def dismiss(self):
        self.clear()
        self.dismissed.emit()

    @property
    def input(self):
        return self._input or ''

    @input.setter
    def input(self, value):
        value = value or ''
        if self._input != value:
            self._input = value
            self.results = filter(self._all_terms, value,
                                  incremental=True, debug=self._debug)

    @property
    def results(self):
        return self._results

    @results.setter
    def results(self, results):
        limit = self._limit
        materialized_results = list(results)
        self._selected_count = len(materialized_results)

        if limit is not None:
            current_items = materialized_results[:limit]

            if self._selected_count > limit:
                self._over_limit()
            else:
                self._under_limit()
        else:
            current_items = materialized_results
            self._under_limit()

        self._index = max(0, min(self._index, len(current_items) - 1))
        self._results = current_items
        self._render_items()
        self._render_counters()

    def _render_items(self):
        items = [item.asdict() for item in self.results]
        if items:
            items[self._index]['selected'] = True
        self._frontend.show_items(items)

    def _render_counters(self):
        self._frontend.update_counters(self._selected_count, self._total_items)

    def get_selected(self):
        items = [r.value for r in self.results]

        if items:
            return items[min(self._index, len(items) - 1)].strip()

    def _candidates_for_completion(self):
        values = self._values_for_completion()

        if self.completion_sep:
            return self._values_until_next_sep(values, len(self.input))
        return list(values)

    def _values_for_completion(self):
        items = (t.value for t in self._all_terms)
        sw = str.startswith
        input = self.input
        return (c for c in items if sw(c, input))

    def _values_until_next_sep(self, values, from_index):
        sep = self.completion_sep
        find = str.find
        return {
            string[:result + 1]
            for result, string in (
                (find(string, sep, from_index), string)
                for string in values
            ) if ~result
        }

    def _over_limit(self):
        self._frontend.over_limit()

    def _under_limit(self):
        self._frontend.under_limit()


class History:
    def __init__(self, history_path, key):
        if not key:
            self.prev = self.next = lambda input: input
            self.add = lambda entry: None
            return

        if not os.path.exists(history_path):
            os.makedirs(os.path.dirname(history_path), exist_ok=True)
            with open(history_path, 'w') as f:
                f.write(json.dumps({}))

        self._history_path = history_path
        self._key = key
        self._all_entries = self._load()
        self._entries = self._all_entries.get(self._key, [])
        self._index = len(self._entries)

    def next(self, _):
        self._index = min(len(self._entries), self._index + 1)

        if self._index == len(self._entries):
            return

        return self._entries[self._index]

    def prev(self, _):
        if len(self._entries) == 0:
            return

        self._index = max(0, self._index - 1)
        return self._entries[self._index]

    def add(self, entry):
        if not entry:
            return

        if entry in self._entries:
            self._entries.remove(entry)
        self._entries.append(entry)

        diff = len(self._entries) - MAX_HISTORY_ENTRIES

        if diff > 0:
            self._entries = self._entries[diff:]

        self._all_entries[self._key] = self._entries
        self._dump()

    def _load(self):
        with open(self._history_path, 'r') as history_file:
            return json.loads(history_file.read())

    def _dump(self):
        with open(self._history_path, 'w') as history_file:
            history_file.write(json.dumps(self._all_entries))


class Frontend:
    def __init__(self, menu):
        basedir = os.path.dirname(__file__)

        with open(os.path.join(basedir, 'menu.html')) as f:
            html = f.read()

        with open(os.path.join(basedir, 'menu.json')) as f:
            config = json.loads(f.read())

        with open(os.path.join(basedir, 'jquery.js')) as f:
            jquery_source = f.read()

        with open(os.path.join(basedir, 'menu.js')) as f:
            frontend_source = f.read()

        self.view = MainView()
        self.view.setHtml(interpolate_html(html, self.view, config))

        frame = self.view.page().mainFrame()
        frame.evaluateJavaScript(jquery_source)
        frame.evaluateJavaScript(frontend_source)

        self.frame = frame

        backend = Backend(menu, self.view)
        self.frame.addToJavaScriptWindowObject('backend', backend)

    def show(self, title=None):
        self.view.show()

    def set_input(self, input):
        self._evaluate("frontend.setInput(%s)" % json.dumps(input))

    def show_items(self, items):
        self._evaluate("frontend.setItems(%s)" % json.dumps(items))

    def select(self, index):
        self._evaluate('frontend.select(%d)' % index)

    def over_limit(self):
        self._evaluate("frontend.overLimit()")

    def under_limit(self):
        self._evaluate("frontend.underLimit()")

    def update_counters(self, selected, total):
        self._evaluate("frontend.updateCounters(%d, %d)" % (selected, total))

    def report_mode(self, mode):
        self._evaluate("frontend.switchPrompt(%s)" % json.dumps(mode.prompt))
        self._evaluate("frontend.reportMode(%s)" % json.dumps(mode.name))

    def _evaluate(self, js):
        self.frame.evaluateJavaScript(js)


class ModeHandler:
    def __init__(self, menu):
        self.input = menu.input
        self._menu = menu
        self._mode = None

    def switch(self, mode):
        if self._mode is not mode:
            self._mode = mode
            self.input = self._menu.input
            self.frontend.report_mode(mode)


class Backend(QObject):
    def __init__(self, menu, parent=None):
        self.menu = menu
        super(Backend, self).__init__(parent)

    @pyqtSlot(str)
    def log(self, message):
        sys.stderr.write(message + "\n")
        sys.stderr.flush()

    @pyqtSlot(str)
    def filter(self, input):
        self.menu.input = input

    @pyqtSlot(str)
    def enter(self, input):
        self.menu.enter(input)

    @pyqtSlot()
    def acceptSelected(self):
        self.menu.accept()

    @pyqtSlot(result=str)
    def getSelected(self):
        selected = self.menu.get_selected()
        if not selected:
            return ''
        return selected

    @pyqtSlot()
    def acceptInput(self):
        self.menu.accept_input()

    @pyqtSlot()
    def next(self):
        self.menu.next()

    @pyqtSlot()
    def prev(self):
        self.menu.prev()

    @pyqtSlot(result=str)
    def historyNext(self):
        return self.menu.history_next()

    @pyqtSlot(result=str)
    def historyPrev(self):
        return self.menu.history_prev()

    @pyqtSlot(result=str)
    def complete(self):
        return self.menu.complete()

    @pyqtSlot()
    def dismiss(self):
        self.menu.dismiss()

    @pyqtSlot(result=str)
    def wordDelimiters(self):
        delimiters = [' ']
        if self.menu.word_delimiters:
            delimiters.extend(self.menu.word_delimiters)
        return ''.join(delimiters)


class MainView(QWebView):
    def __init__(self, parent=None):
        super(MainView, self).__init__(parent)
        self.setFocusPolicy(Qt.StrongFocus)
        self.setWindowFlags(Qt.WindowStaysOnTopHint)

    def show(self, title=None):
        r = super(MainView, self).show()
        self.activateWindow()

        if title is not None:
            self.setWindowTitle(title)

        screensize = QApplication.desktop().screenGeometry()
        size = self.geometry()
        hpos = (screensize.width() - size.width()) // 2
        vpos = (screensize.height() - size.height()) // 2
        self.move(hpos, vpos)
        return r


def default_colors(view):
    palette = view.palette()

    def color(role_name, a=1.0):
        role = getattr(QPalette, role_name)
        c = palette.color(role)
        return "rgba(%d,%d,%d,%f)" % (c.red(), c.green(), c.blue(), float(a))

    def disabled(role_name, a=1.0):
        role = getattr(QPalette, role_name)
        c = palette.color(QPalette.Disabled, role)
        return "rgba(%d,%d,%d,%f)" % (c.red(), c.green(), c.blue(), float(a))

    def inactive(role_name, a=1.0):
        role = getattr(QPalette, role_name)
        c = palette.color(QPalette.Inactive, role)
        return "rgba(%d,%d,%d,%f)" % (c.red(), c.green(), c.blue(), float(a))

    return {
        "background-color": color('Base'),
        "color": color('Text'),
        "prompt-background-color": color('Base'),
        "prompt-color": color('Link'),
        "prompt-over-limit-color": color('LinkVisited'),
        "input-background-color": color('Base'),
        "input-color": color('Text'),
        "input-not-found-color": disabled('Text'),
        "input-history-color": color('Text'),
        "counters-color": inactive('Text'),
        "entries-background-color-gradient-start": color('Base', 0),
        "entries-background-color-gradient-end": color('Base', 0),
        "entries-background-color": color('Base'),
        "entries-alternate-background-color": color('AlternateBase'),
        "entries-color": inactive('Text'),
        "entries-alternate-color": inactive('Text'),
        "entries-hl-background-color": color('Highlight'),
        "entries-alternate-hl-background-color": color('Highlight'),
        "entries-hl-color": color('HighlightedText'),
        "entries-alternate-hl-color": color('HighlightedText'),
        "selected-entry-background-color": color('Highlight'),
        "selected-entry-color": color('HighlightedText'),
    }


def apply_default_colors(view, theme):
    colors = default_colors(view)
    colors.update(theme)
    return colors


def interpolate_html(template, view, config):
    theme = apply_default_colors(view, config.get('theme', {}))

    for key, value in theme.items():
        template = template.replace('%(' + key + ')s', value)
    return template.\
        replace('%(initial-value)s', '').replace('%(entries-class)s', '')


class MenuApp(QObject):
    selected = pyqtSignal(str)
    dismissed = pyqtSignal()

    def __init__(self, title=None):
        super(MenuApp, self).__init__()

        self.app = QApplication(sys.argv)
        self.menu = Menu()
        self.frontend = Frontend(self.menu)

        self.menu.connect(self.frontend)

        self.menu.selected.connect(self.selected.emit)
        self.menu.dismissed.connect(self.dismissed.emit)

    def setup(self, *args, **kw):
        title = kw.pop('title', None)
        self.menu.setup(*args, **kw)
        self.restore(title=title)

    def minimize(self):
        self.frontend.view.hide()

    def restore(self, title=None):
        self.frontend.view.show(title=title)

    def exec_(self):
        return self.app.exec_()

    def quit(self):
        return self.app.quit()


class PatternCache(object):
    def __init__(self):
        self._cache = {}

    def update(self, patterns, matches, debug=False):
        if debug:
            def debug(fn): sys.stderr.write(fn())
        else:
            def debug(fn): return

        patterns = tuple(p.value for p in patterns)
        debug(lambda: "updating cache for patterns: {}\n".format(patterns))
        self._cache[patterns] = frozenset(matches)

    def find(self, patterns, default=frozenset(), debug=False):
        patterns = tuple(p.value for p in patterns)
        cached = None
        best_pattern = ()

        if debug:
            def debug(fn): sys.stderr.write(fn())
        else:
            def debug(fn): return

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


class IncrementalCache(object):
    def __init__(self):
        self._cache = {}

    def clear(self):
        self._cache.clear()

    def update(self, patterns, matches, debug=False):
        if len(set(type(p) for p in patterns)) == 1:
            self._cache[type(patterns[0])].update(patterns, matches,
                                                  debug=debug)

    def find(self, patterns, default=frozenset(), debug=False):
        for pattern in patterns:
            self._cache.setdefault(type(pattern), PatternCache())

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


def run(items, **kw):
    app = MenuApp()

    def select(result):
        print(result)
        app.quit()

    app.selected.connect(select)
    app.dismissed.connect(app.quit)

    app.setup(items, **kw)
    return app.exec_()
