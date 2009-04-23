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

from re import compile
from time import strptime, mktime
from urllib import urlopen
from datetime import datetime

from pylibs.pkgbuild import PkgBuild

re_href = compile('.a href=.(\S+)\/">')
re_time = compile('(\d{2})-(\S{3})-(\d{4}) (\d{2}):(\d{2})\s+')

def foreach_aur():
    f = urlopen("http://aur.archlinux.org/packages/?")

    for line in f.readlines():
        href = re_href.search(line)

        if not href:
            continue

        time = re_time.search(line)

        if time:
            yield (href.group(1), \
                   datetime.fromtimestamp(mktime(
                       strptime("%s %s %s %s:%s" % (time.group(1),
                                                    time.group(2),
                                                    time.group(3),
                                                    time.group(4),
                                                    time.group(5)),
                                "%d %b %Y %H:%M"))))
    f.close()

class AurException(Exception): pass

class AurPkgBuild(PkgBuild):
    def __init__(self, pkgname):
        f = urlopen("http://aur.archlinux.org/packages/%s/%s/PKGBUILD" \
                    % (pkgname, pkgname))

        if f.getcode() != 200:
            raise AurException("Package %s not found." % pkgname)

        super(PkgBuild, self).__init__(None, f)
