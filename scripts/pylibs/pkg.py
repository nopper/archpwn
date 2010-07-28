# -*- coding: utf-8 -*-
# Copyright (C) 2010 Francesco Piccinno
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
import sys
import os.path

try:
    from tarfile import TarFile
    from lzma import LZMAFile
except ImportError:
    print "You need to install python-pyliblzma to handle .xz pkg files"

from tempfile import mkstemp
from collections import defaultdict

class Pkg(object):
    def __init__(self, path):
        if path.endswith('.gz'):
            self.fd = TarFile.gzopen(path)
        elif path.endswith('.xz'):
            self.fd = TarFile.open(fileobj=LZMAFile(path))
        else:
            raise Exception('Unsupported file type %s' % path)

        self.pkg_info = defaultdict(list)
        self.members = []

        # Extract most used information

        if self.parse_pkginfo():
            self.parse_contents()

        self.name = self.pkg_info.get('pkgname')
        self.desc = self.pkg_info.get('pkgdesc')[0]
        self.depends = self.pkg_info.get('depend') or []
        self.groups = self.pkg_info.get('group') or []

        if isinstance(self.name, (list, tuple)) and len(self.name) == 1:
            self.name = self.name[0]

    def is_executable(self, member):
        xbit = 7 << 6

        if member.path.endswith('.desktop'):
            raise StopIteration()

        if member.mode & xbit == xbit and \
           member.isfile():

            name = member.path

            # Ignore too nested executable
            if name.count('/') > 3:
                return False

            blacklist = True

            for white in ('bin/', 'sbin/',
                          'usr/share', 'usr/bin',
                          'usr/sbin'):

                if name.startswith(white):
                    blacklist = False
                    break

            if blacklist:
                return False

            name = os.path.basename(name)

            # Ignore also UPPER file names
            if name.isupper():
                return False

            if '.' not in name:
                return True

            for ext in ('.sh', ):
                if name.endswith(ext):
                    return True

        return False

    def parse_contents(self):
        try:
            members = filter(self.is_executable,
                             self.fd.members)

            self.members = [member.path for member in members]
            self.members.sort()
        except StopIteration:
            self.members = []
            #self.pkg_info.clear()

    def parse_pkginfo(self):
        try:
            member = self.fd.getmember('.PKGINFO')
            buff = self.fd.extractfile(member)
            return self.parse_buffer(buff)
        except Exception, exc:
            return False

    def parse_buffer(self, buff):
        for line in buff.readlines():
            line = line.strip()

            if line[0] == '#':
                continue

            key, value = line.split('=', 1)
            self.pkg_info[key.strip()].append(value.strip())

        return 'group' in self.pkg_info

if __name__ == '__main__':
    p = Pkg(sys.argv[1])
    print p.members
    print p.pkg_info
