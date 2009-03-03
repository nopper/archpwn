#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (C) 2008 Francesco Piccinno
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

class UtilLogger(Logger, object):
    def __init__(self, name, level):
        Logger.__init__(self, name, level)
        self.formatter = self.format

        handler = StreamHandler()
        handler.setFormatter(self.formatter)

        self.addHandler(handler)

    def get_formatter(self):
        return self.__formatter

    def set_formatter(self, fmt):
        self.__formatter = Formatter(fmt)

    format = "%(levelname)s %(message)s"
    formatter = property(get_formatter, set_formatter, doc="")
    __formatter = Formatter(format)

log = UtilLogger("Util", 10)

def foreach_pkgbuild(pdir):
    srcdir = pdir
    category = None

    for root, dirs, files in os.walk(pdir):
        if os.path.isfile(os.path.join(srcdir, root, "group-overlay")):
            # Assume a category
            category = os.path.basename(root)

        for dir in (dir for dir in dirs if os.path.isfile(
                    os.path.join(srcdir, root, dir, "PKGBUILD"))):
            yield (os.path.join(srcdir, root, dir), category)

        category = None

class ConsoleP(object):
    def write(self, txt): print txt
    def info(self, txt): log.info(txt)
    def error(self, txt): log.error(txt)
    def warning(self, txt): pass#log.warning(txt)
    def debug(self, txt): pass#log.debug(txt)

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
