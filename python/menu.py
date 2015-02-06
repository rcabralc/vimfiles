"""Menu.

Usage:
    menu [options]

Options:
    -a, --algorithm ALGORITHM
        Choose the algorithm (`fuzzy' or `re').  [Default: fuzzy].

    -l, --limit LIMIT
        Limit output up to LIMIT results.  Use a negative number to not limit
        output.

    -i, --input INPUT
        Use INPUT as a initial value.

    --completion-sep SEP
        Separator used for completion.  Without this, completion works by
        completing longest common match.  This can be used to complete only
        directories in a list of files, for instance: use '/' (or OS path
        separator) for this.

    --history-key KEY
        A key which must be unique to store/retrieve history.  Any string can
        be used.  History is enabled only if this option is provided and is not
        empty.

        For instance, if listing all files under a specific directory, use that
        directory as the key.  Next time this program is used for this
        directory, it'll remember the previous input, allowing the user to
        reuse it.

    --preformatted
        Options should have whitespace preserved (that is, not collapsed).  A
        monospaced font is used for the entries.

    --daemonize
        Create a daemon process if none exists, bring its window to the top and
        connect to it.

        When the daemon outputs an option, that option is written to the
        standard output of this process, which then exits, leaving the daemon
        running in background.

        Keeping a daemon in background can improve further startups.

    --kill-daemon
        Kill the daemon if it exists, and exit immediately.  All other options
        are ignored.

    -D, --debug
        Print additional information to STDERR.

    -h, --help
        Show this.

Key bindings:

    Enter:  Accept the selected item (will print it to STDOUT and exit)
    Ctrl+Y: Accept the input (will print it to STDOUT and exit)
    Esc:    Quit, without printing anything.
    Tab:    Complete.
    CTRL+J: Select next entry.
    CTRL+K: Select previous entry.
    Ctrl+N: Get next history entry and use it as the input.
    Ctrl+P: Get previous history entry and use it as the input.
"""

from docopt import docopt
from filters import filter
from itertools import cycle
from PyQt5.QtCore import QObject, pyqtSlot
from PyQt5.QtWebKitWidgets import QWebView
from PyQt5.QtWidgets import QApplication

import json
import os
import sys


class Mode:
    def __init__(self, name, prompt):
        self.name = name
        self.prompt = prompt


MAX_HISTORY_ENTRIES = 100

input_mode = Mode('input', 'I')
history_mode = Mode('history', 'H')

fuzzy_algorithm = Mode('fuzzy', 'F:')
regexp_algorithm = Mode('re', 'R:')
algorithms = dict((a.name, a) for a in [fuzzy_algorithm, regexp_algorithm])
iter_algorithms = cycle(algorithms.values())


class Menu:
    def __init__(self, items, limit=None, sep=None, debug=False):
        self.all_items = items
        self._total_items = len(items)
        self.index = 0
        self.limit = limit
        self.sep = sep
        self._input = ''
        self.debug = debug

    def get_selected(self):
        items = [i.original_value for i in self.results]

        if items:
            return items[min(self.index, len(items) - 1)].strip()

    def accept_input(self):
        return self.input

    def next(self):
        self.index = min(self.index + 1, len(self.results) - 1)
        self.frontend.select(self.index)

    def prev(self):
        self.index = max(self.index - 1, 0)
        self.frontend.select(self.index)

    def complete(self):
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

    @property
    def algorithm(self):
        return self._algorithm

    @algorithm.setter
    def algorithm(self, value):
        self._algorithm = value
        self.frontend.prompt = value.prompt

    def switch_algorithm(self):
        self.algorithm = next(iter_algorithms)

    @property
    def input(self):
        return self._input

    @input.setter
    def input(self, value):
        self._input = value
        self.results = filter(self.all_items, value,
                              algorithm=self.algorithm.name,
                              incremental=True,
                              debug=self.debug)

    @property
    def results(self):
        return self._results

    @results.setter
    def results(self, results):
        limit = self.limit
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

        self.index = max(0, min(self.index, len(current_items) - 1))
        self._results = current_items
        self.render_items()
        self.render_counters()

    def render_items(self):
        items = [item.asdict() for item in self.results]
        if items:
            items[self.index]['selected'] = True
        self.frontend.show_items(items)

    def render_counters(self):
        self.frontend.update_counters(self._selected_count, self._total_items)

    def _candidates_for_completion(self):
        values = self._values_for_completion()

        if self.sep:
            return self._values_until_next_sep(values, len(self.input))
        return list(values)

    def _values_for_completion(self):
        items = self.all_items
        sw = str.startswith
        input = self.input
        return (c for c in items if sw(c, input))

    def _values_until_next_sep(self, values, from_index):
        sep = self.sep
        find = str.find
        return {
            string[:result + 1]
            for result, string in (
                (find(string, sep, from_index), string)
                for string in values
            ) if ~result
        }

    def _over_limit(self):
        self.frontend.over_limit()

    def _under_limit(self):
        self.frontend.under_limit()


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
    def __init__(self, frame, bridge):
        self.frame = frame
        self.frame.addToJavaScriptWindowObject('backend', bridge)

    def init(self):
        self._evaluate('frontend.init()')

    def show_items(self, items):
        self._evaluate("frontend.setItems(%(items)s);" % dict(
            items=json.dumps(items)
        ))

    def select(self, index):
        self._evaluate('frontend.select(%d)' % index)

    @property
    def prompt(self):
        return self._prompt

    @prompt.setter
    def prompt(self, value):
        self._prompt = value
        self._evaluate("frontend.switchPrompt(%s)" % json.dumps(value))

    def over_limit(self):
        self._evaluate("frontend.overLimit()")

    def under_limit(self):
        self._evaluate("frontend.underLimit()")

    def update_counters(self, selected, total):
        self._evaluate("frontend.updateCounters(%d, %d)" % (selected, total))

    def report_mode(self, mode):
        self._evaluate("frontend.reportMode(%s)" % json.dumps(mode.name))

    def _evaluate(self, js):
        self.frame.evaluateJavaScript(js)


class Input:
    def __init__(self, menu, frontend, initial_mode, value):
        self._menu = menu
        self._mode = initial_mode
        self._frontend = frontend

        self.value = value

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        self._value = value
        self._menu.input = value

    def enter(self, value):
        self.value = value
        self.switch_mode(input_mode)

    def switch_mode(self, mode):
        if self._mode is not mode:
            self._mode = mode
            self._inputs[self._mode] = self.value
            self._frontend.report_mode(mode)


class ModeHandler:
    def __init__(self, menu, initial_mode):
        self.input = menu.input
        self._menu = menu
        self._mode = initial_mode

    def switch(self, mode):
        if self._mode is not mode:
            self._mode = mode
            self.input = self._menu.input
            self.frontend.report_mode(mode)


class JSBridge(QObject):
    def __init__(self, app, menu, history, mode_handler, parent=None):
        self.app = app
        self.menu = menu
        self.history = history
        self.mode_handler = mode_handler
        super(JSBridge, self).__init__(parent)

    @pyqtSlot(str)
    def log(self, message):
        sys.stderr.write(message + "\n")
        sys.stderr.flush()

    @pyqtSlot(str)
    def filter(self, input):
        self.menu.input = input

    @pyqtSlot(str)
    def enter(self, input):
        # self.input.enter(input)
        self.menu.input = input
        self.mode_handler.switch(input_mode)

    @pyqtSlot()
    def acceptSelected(self):
        selected = self.menu.get_selected()
        if selected:
            print(selected)
            self.history.add(selected)
            self.app.quit()

    @pyqtSlot()
    def acceptInput(self):
        # print(self.input.value)
        print(self.menu.input)
        self.history.add(self.menu.input)
        self.app.quit()

    @pyqtSlot()
    def next(self):
        self.menu.next()

    @pyqtSlot()
    def prev(self):
        self.menu.prev()

    @pyqtSlot(result=str)
    def historyNext(self):
        entry = self.history.next(self.mode_handler.input)
        self.mode_handler.switch(history_mode)
        return (entry if entry else self.mode_handler.input)

    @pyqtSlot(result=str)
    def historyPrev(self):
        entry = self.history.prev(self.mode_handler.input)
        self.mode_handler.switch(history_mode)
        return (entry if entry else self.mode_handler.input)

    @pyqtSlot(result=str)
    def complete(self):
        self.mode_handler.switch(input_mode)
        return self.menu.complete()

    @pyqtSlot()
    def switchAlgorithm(self):
        self.menu.switch_algorithm()
        self.menu.input = self.menu.input

    @pyqtSlot()
    def dismiss(self):
        self.app.quit()


class MainView(QWebView):
    def show(self):
        r = super(MainView, self).show()
        screensize = QApplication.desktop().screenGeometry()
        size = self.geometry()
        hpos = (screensize.width() - size.width()) / 2
        vpos = (screensize.height() - size.height()) / 2
        self.move(hpos, vpos)
        return r


def run(items, algorithm_name, input=None, **kw):
    basedir = os.path.dirname(__file__)
    with open(os.path.join(basedir, 'menu.html')) as f:
        html = f.read()

    with open(os.path.join(basedir, 'menu.json')) as f:
        config = json.loads(f.read())

    with open(os.path.join(basedir, 'jquery.js')) as f:
        jquery_source = f.read()

    with open(os.path.join(basedir, 'menu.js')) as f:
        frontend_source = f.read()

    history_path = os.path.join(basedir, 'history.json')
    history_key = kw.pop('history_key', None)
    preformatted = kw.pop('preformatted', False)

    if algorithm_name not in algorithms.keys():
        exit('Unknown algorithm: %r' % algorithm_name)
    algorithm = algorithms[algorithm_name]
    input = input or ''

    app = QApplication(sys.argv)
    menu = Menu(items, **kw)
    history = History(history_path, history_key)
    mode_handler = ModeHandler(menu, input_mode)

    bridge = JSBridge(app, menu, history, mode_handler)
    view = MainView()
    frame = view.page().mainFrame()

    view.setHtml(interpolate_html(html, config,
                                  input=input,
                                  preformatted=preformatted))
    frame.evaluateJavaScript(jquery_source)
    frame.evaluateJavaScript(frontend_source)

    frontend = Frontend(frame, bridge)
    frontend.report_mode(input_mode)

    menu.frontend = frontend
    mode_handler.frontend = frontend

    menu.algorithm = algorithm
    menu.input = input

    view.show()
    frontend.init()
    return app.exec_()


def interpolate_html(template, config, input='', preformatted=False):
    for key, value in config.get('theme', {}).items():
        template = template.replace('%(' + key + ')s', value)
    return template.\
        replace('%(initial-value)s', input).\
        replace('%(entries-class)s', 'preformatted' if preformatted else '')


def main():
    args = docopt(__doc__)

    limit = args['--limit']
    limit = int(limit) if limit and int(limit) >= 0 else None

    return run(
        sys.stdin.readlines(),
        args['--algorithm'] or 'fuzzy',
        input=args['--input'],
        limit=limit,
        sep=args['--completion-sep'],
        history_key=args['--history-key'],
        preformatted=args['--preformatted'],
        debug=args['--debug']
    )


if __name__ == '__main__':
    sys.exit(main())
