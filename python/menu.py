"""Menu.

Usage:
    menu [options]

Options:
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

    --word-delimiters DELIMITERS
        Delimiters used for words.

    --history-key KEY
        A key which must be unique to store/retrieve history.  Any string can
        be used.  History is enabled only if this option is provided and is not
        empty.

        For instance, if listing all files under a specific directory, use that
        directory as the key.  Next time this program is used for this
        directory, it'll remember the previous input, allowing the user to
        reuse it.

    --accept-input
        Allow any text typed in the search input to be accepted through
        Ctrl-Enter.

    --title TITLE
        Set the window title to TITLE.

    -d, --daemonize
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

    Enter:      Accept the selected item (will print it to STDOUT and exit)
    Ctrl+Enter: Accept the input (will print it to STDOUT and exit)
    Esc:        Quit, without printing anything.
    Tab:        Complete.
    CTRL+J:     Select next entry.
    CTRL+K:     Select previous entry.
    Ctrl+N:     Get next history entry and use it as the input.
    Ctrl+P:     Get previous history entry and use it as the input.
    Ctrl+Y:     Copy selected entry to the input box.
"""

from docopt import docopt

import json
import os
import socket
import sys
import subprocess
import time


daemon_socket_file = '/tmp/pythonmenu.sock'
basedir = os.path.dirname(__file__)


def main(args):
    if args['--kill-daemon']:
        os.execl(os.path.join(basedir, 'menud.py'), 'menud.py', '--kill')

    limit = args['--limit']
    limit = int(limit) if limit and int(limit) >= 0 else None

    fn = runner(daemonize=args['--daemonize'])

    return fn(
        sys.stdin.readlines(),
        input=args['--input'],
        limit=limit,
        sep=args['--completion-sep'],
        delimiters=list((args['--word-delimiters'] or '')),
        history_key=args['--history-key'],
        accept_input=args['--accept-input'],
        title=args['--title'],
        debug=args['--debug']
    )


def non_daemonized_runner():
    from menuapp import run
    return run


def spawn_daemon(max_attempts=10):
    class Attempt:
        def get_socket(self):
            if not os.path.exists(daemon_socket_file):
                time.sleep(0.5)
                return
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            sock.connect(daemon_socket_file)
            return sock

    if not os.path.exists(daemon_socket_file):
        subprocess.call([os.path.join(basedir, 'menud.py'), '--keep-stderr'])

    for i in range(max_attempts):
        yield Attempt()


def get_daemon_socket():
    for attempt in spawn_daemon():
        sock = attempt.get_socket()
        if sock:
            return sock
    raise RuntimeError("could not connect to daemon")


def runner(daemonize=False):
    if not daemonize:
        return non_daemonized_runner()

    sock = get_daemon_socket()

    def fn(items, **kw):
        sock.sendall(b'PROMPT\n')
        sock.sendall((json.dumps(kw) + '\n').encode('utf-8'))
        for item in items:
            if not item.endswith('\n'):
                item = item + '\n'
            sock.sendall(item.encode('utf-8'))
        sock.sendall(b'\n')
        result = sock.recv(4096)
        if result:
            sys.stdout.write(result.decode('utf-8'))
        sock.close()
        return 0
    return fn


if __name__ == '__main__':
    sys.exit(main(docopt(__doc__)))
