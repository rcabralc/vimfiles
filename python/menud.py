#!/usr/bin/env python
"""
Usage:
    menud [--foreground | --kill]

Description:
    This program starts a menu as a daemon.

Options:
    --foreground  Run attached to the terminal (don't daemonize).
    --kill        Kill the daemon if already running, return 1 otherwise.
    -h, --help    Show this.
"""

from docopt import docopt
from menuapp import MenuApp
from PyQt5.QtCore import QThread, QObject, pyqtSignal

import daemon
import json
import os
import queue
import socket
import sys


socket_file = '/tmp/pythonmenu.sock'


def unlink_socket():
    try:
        os.unlink(socket_file)
    except OSError:
        if os.path.exists(socket_file):
            raise


class Command:
    pass


class PromptCommand(Command):
    def __init__(self, request, data):
        self._request = request
        self._data = data

    @property
    def items(self):
        return self._data.get('items', [])

    @property
    def options(self):
        return self._data.get('options', {})

    def execute(self, menu):
        menu.prompt(self._request, self)


class KillCommand(Command):
    def __init__(self, request):
        self._request = request

    def execute(self, menu):
        menu.kill(self._request, self)


class Request:
    def __init__(self, container, sock):
        self.container = container
        self.sock = sock
        self._command = None
        self._done = False

    @property
    def command(self):
        if self._command is None:
            data = self.sock.readline().strip(self.sock.separator)
            if data == 'PROMPT':
                data = dict(options=json.loads(self.sock.readline()), items=[])
                item = self.sock.readline()
                while item != self.sock.separator:
                    data['items'].append(item)
                    item = self.sock.readline()
                self._command = PromptCommand(self, data)
            elif data == 'KILL':
                self._command = KillCommand(self)
        return self._command

    def respond(self, message):
        self.sock.writeline(message)
        return self.done()

    def done(self):
        if not self._done:
            self.sock.close()
            self.container.task_done()
            self._done = True
        return self


class Menu(QObject):
    finished = pyqtSignal()

    def __init__(self):
        super(Menu, self).__init__()

        self._app = MenuApp()
        self._app.minimize()
        self._current_request = None

        def respond(result):
            self._app.minimize()
            if self._current_request is not None:
                self._current_request.respond(result)
                self._current_request = None

        def cancel():
            if self._current_request is not None:
                self._current_request.done()
                self._current_request = None

        self._app.selected.connect(respond)
        self._app.dismissed.connect(cancel)
        self._app.dismissed.connect(self._app.minimize)

    def exec_(self):
        return self._app.exec_()

    def prompt(self, request, command):
        self._current_request = request
        self._app.restore()

        try:
            self._app.setup(command.items, **command.options)
        except:
            request.done()
            raise

    def kill(self, request, command):
        self.finished.emit()
        self._app.quit()


class LinewiseSocket:
    def __init__(self, socket_file, separator=b'\n', encoding='utf-8'):
        self._socket_file = socket_file
        self._sep = separator
        self.encoding = encoding
        self.separator = separator.decode(self.encoding)
        self._rbuffer = b''

    def readline(self):
        message = self._rbuffer
        newline = message.find(self._sep)
        while not ~newline:
            chunk = self._sock.recv(4096)
            if not chunk:
                raise RuntimeError('socket connection broken')
            message = message + chunk
            newline = message.find(self._sep)

        newline += 1
        self._rbuffer = message[newline:]
        return message[:newline].decode(self.encoding)

    def writeline(self, message):
        message = message.encode(self.encoding)
        if not message.endswith(self._sep):
            message = message + self._sep
        self._sock.sendall(message)

    def accept(self):
        sock, _ = self._sock.accept()
        lsock = LinewiseSocket(self._socket_file)
        lsock._sock = sock
        return lsock

    def close(self):
        self._sock.close()

    def __enter__(self):
        self._sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sock.bind(self._socket_file)
        self._sock.listen(1)
        return self

    def __exit__(self, type, value, traceback):
        self.close()


class Server(QObject):
    dispatched = pyqtSignal(Command)

    def __init__(self, requests, logger=None):
        super(Server, self).__init__()
        self._requests = requests
        self._logger = logger

    def run(self):
        while True:
            command = self._requests.get().command
            if self._logger:
                self._logger.write('received command: %r\n' % command)
            self.dispatched.emit(command)


class Listener(QObject):
    def __init__(self, sock, requests):
        super(Listener, self).__init__()
        self._sock = sock
        self._requests = requests

    def run(self):
        while True:
            sock = self._sock.accept()
            self._requests.put(Request(self._requests, sock))


def run(logger=None):
    menu = Menu()
    requests = queue.Queue()

    def resolve(command):
        command.execute(menu)

    with LinewiseSocket(socket_file) as sock:
        if logger:
            logger.write('listening on ' + socket_file + '\n')

        server_thread = QThread()
        server = Server(requests, logger=logger)
        server.moveToThread(server_thread)
        server_thread.started.connect(server.run)

        listener_thread = QThread()
        receiver = Listener(sock, requests)
        receiver.moveToThread(listener_thread)
        listener_thread.started.connect(receiver.run)

        server.dispatched.connect(resolve)
        menu.finished.connect(server_thread.exit)
        menu.finished.connect(listener_thread.exit)
        menu.finished.connect(unlink_socket)

        server_thread.start()
        if logger:
            logger.write('started server thread\n')

        listener_thread.start()
        if logger:
            logger.write('started receiver thread\n')

        return menu.exec_()


def kill():
    if not os.path.exists(socket_file):
        return 1

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(socket_file)
    sock.sendall(b'KILL\n')
    sock.close()

    return 0


def main(args):
    if args['--foreground']:
        return sys.exit(run(sys.stdout))

    if args['--kill']:
        return sys.exit(kill())

    unlink_socket()
    with daemon.DaemonContext():
        run()


if __name__ == '__main__':
    args = docopt(__doc__)
    main(args)
