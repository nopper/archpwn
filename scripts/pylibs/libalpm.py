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

import ctypes
from pylibs.utils import Singleton

class LibALPM(Singleton):
    def __init__(self):
        self.libalpm = ctypes.cdll.LoadLibrary("libalpm.so")
    
    def vercmp(self, a, b):
        if not isinstance(a, basestring) or \
           not isinstance(b, basestring):
            raise Exception("Incompatible type. I need a str")

        return self.libalpm.alpm_pkg_vercmp(str(a), str(b))

libalpm = LibALPM()
