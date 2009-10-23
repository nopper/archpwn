#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (C) 2008-2009 Francesco Piccinno
#
# Author: Francesco Piccinno <stack.box@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import os
import os.path

import sys

import logging.config
from logging import Logger, StreamHandler, Formatter, addLevelName

if os.name == 'posix':
    reset = "\033[1;0m"
    yellow = "\033[1;33m"
    green = "\033[1;32m"
    brown = "\033[0;33m"
    red = "\033[1;31m"
else:
    reset = yellow = green = brown = red = ''

addLevelName(10, '%sDBG%s' % (brown, reset))
addLevelName(20, '%s>>>%s' % (green, reset))
addLevelName(30, '%s***%s' % (yellow, reset))
addLevelName(40, '%s!!!%s' % (red, reset))
addLevelName(50, '%s###%s' % (red, reset))

logging.config.fileConfig(os.path.join(os.path.dirname(__file__), 'logging.ini'))

def foreach_pkgbuild(pdir):
    for root, dirs, files in os.walk(pdir):
        if len(files) == 1 and files[0] == 'PKGBUILD':
            yield root

class ConsoleP(object):
    def __init__(self, name):
        self.log = logging.getLogger(name)
    def write(self, txt): print txt
    def info(self, txt): self.log.info(txt)
    def error(self, txt): self.log.error(txt)
    def warning(self, txt): self.log.warning(txt)
    def debug(self, txt): self.log.debug(txt)

class Singleton(object):
    """
    A class for singleton pattern
    Support also gobject if Singleton base subclass if specified first
    """

    instances = {}
    def __new__(cls, *args, **kwargs):
        if Singleton.instances.get(cls) is None:
            cls.__original_init__ = cls.__init__
            Singleton.instances[cls] = object.__new__(cls, *args, **kwargs)
        elif cls.__init__ == cls.__original_init__:
            def nothing(*args, **kwargs):
                pass
            cls.__init__ = nothing
        return Singleton.instances[cls]

class Animator:
    def __init__(self):
        self.idx = 0
        self.status = ('-', '\\', '|', '/')

    def update(self, txt):
        sys.stdout.write("%s %s\r" % (self.status[self.idx], txt))
        self.idx += 1
        self.idx %= 4

    def stop(self, txt):
        self.idx = 0
        self.update(txt + "\n")

def escape_deps(l):
    if not l:
        return []

    r = []
    for d in l:
        ops = (">=", "<=", "=", ">", "<")

        for op in ops:
            if op in d:
                r.append(d.split(op)[0])
                break
        else:
            r.append(d)
    return r

class Node(object):
    def __init__(self, name, pdir=None):
        self.pname = name
        self.pdir = pdir
        self.deps = []
        self.root = None

    def add_dep(self, node):
        if node not in self.deps:
            self.deps.append(node)

        node.root = self

    def get_depth(self):
        idx = 0
        root = self.root

        while root:
            root = root.root
            idx += 1

        return idx

    def __iter__(self):
        yield self

        for dep in self.deps:
            yield dep

    def __repr__(self):
        return "%s -> %s" % (self.root, self.pname)

class RNode(object):
    def __init__(self, name, pdir=None):
        self.pname = name
        self.pdir = pdir
        self.deps = []
        self.rdeps = []

    def add_deps(self, lst):
        for dep in lst:
            self.add_dep(dep)

    def add_dep(self, node):
        if node not in self.deps:
            self.deps.append(node)
        if self not in node.rdeps:
            node.rdeps.append(self)

    def __iter__(self):
        yield self

        for child in self.rdeps:
            yield child

    def __repr__(self):
        return self.pname
