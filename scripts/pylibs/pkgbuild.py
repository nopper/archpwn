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

import sys
import shlex

from pylibs.utils import ConsoleP

class Scope(ConsoleP):
    def __init__(self):
        self.scopes = []
        self.scopes.append({"pkgdir" : "", "srcdir" : "", "startdir" : ""})
        self.current = 0

    def allocate_var(self, token):
        self.debug("Allocating variable `%s`" % token)
        return (self.cscope, token)

    def parse_assign(self, var, op, token):
        scope, var = var

        if op == '=':
            scope[var] = token
            self.debug("Assigning `%s` to variable `%s`" % (token, var))

    def escape(self, txt):
        ret = ""
        escape = False
        variable = 0
        variable_val = ""

        for i in txt:

            if escape:
                ret += i
                escape = False
                continue

            if i == '\\':
                escape = True
                continue

            if i == '$':
                variable_val = ""
                variable = 1
                continue
            if variable == 1 and i == '{':
                variable = 2
                continue
            if variable == 2 and i == '}':
                if variable_val.count("/") >= 2:
                    # This handles expressions like: ${pkgver/-/_/}
                    li = variable_val.index("/")
                    ri = variable_val.rindex("/")

                    vname = variable_val[:li]
                    vold = variable_val[li+1:ri]
                    vnew = variable_val[ri+1:]

                    ret += self.cscope[vname].replace(vold, vnew)
                else:
                    ret += self.cscope[variable_val]

                variable = 0
                variable_val = ""
                continue
            if variable >= 1:
                if variable == 1 and i in '-./':
                    try:
                        ret += self.cscope[variable_val]
                    except:
                        if "_" in variable_val:
                            a = variable_val.split("_")
                            ret += self.cscope[a[0]]
                            ret += "_"

                            try:
                                ret += "".join(a[1:])
                            except:
                                pass

                    ret += i

                    variable = 0
                    variable_val = ""
                else:
                    variable_val += i

                continue

            ret += i

        self.debug("Parsed `%s` => `%s`" % (txt, ret))
        return ret
    
    def increase_level(self):
        pass
    def decrease_level(self):
        pass
    
    def dump(self):
        for k, v in self.cscope.items():
            self.debug("%s => %s" % (k, v))

    def get_scope(self):
        return self.scopes[self.current]
    def set_scope(self, idx):
        self.current = idx

    def __getitem__(self, x):
        return self.cscope.get(x)

    cscope = property(get_scope, set_scope)

class Interpreter(ConsoleP):
    ST_FNC, \
    ST_VAR, \
    ST_OPR, \
    ST_VAL, \
    ST_ERR = range(5)

    def __init__(self, path, data=None):
        if path is None:
            self.eval = shlex.shlex(data, posix=True)
        else:
            self.eval = shlex.shlex(open(path, "r").read(), posix=True)

        self.eval.whitespace = " \t"
        self.eval.wordchars += '.:/${}-~'
        self.eval.commenters = '#'
        self.state = self.ST_VAR
        self.scope = Scope()

        self.parse()

    def get(self, x):
        return self.scope[x]

    def parse(self):
        var = None
        operator = None

        #self.eval.debug = 1

        for token in self.eval:
            if token == ';':
                continue
            elif token == '\n':
                if self.state != self.ST_FNC:
                    self.state = self.ST_VAR
                continue
            elif token in ('[', ']', '&'):
                self.warning("Using conditional if in short form. Using last set")
                continue
            elif self.state == self.ST_FNC:
                if token == '}':
                    self.state = self.ST_VAR
                continue

            elif self.state == self.ST_VAR:
                var = self.scope.allocate_var(token)
                self.state = self.ST_OPR
                continue

            elif self.state == self.ST_OPR:
                if var is None:
                    self.error("Error before %s. No previous variable to be assigned." % token)

                if token == '(' or \
                   token == ')':
                    continue
                
                if token == '{':
                    self.state = self.ST_FNC
                    continue

                operator = token
                self.state = self.ST_VAL
                continue

            elif self.state == self.ST_VAL:
                if var is None or operator is None:
                    self.error("bhuu")

                if token == '(':
                    arr_val = []
                    token = self.eval.get_token()

                    if token == '$':
                        # Probably we are in $() or something like that
                        token = self.eval.get_token()
                        if token == '(':

                            while self.eval.get_token() != ')':
                                continue

                            token = self.eval.get_token()

                    while token != ')':
                        if token != '\n':
                            arr_val.append(self.scope.escape(token))
                        token = self.eval.get_token()
                    
                    self.scope.parse_assign(var, operator, tuple(arr_val))
                else:
                    self.scope.parse_assign(var, operator, self.scope.escape(token))

                self.state = self.ST_VAR
                continue

        self.scope.dump()

class PkgBuild(Interpreter):
    def get_output(self):
        return "%s-%s-%s-%s.pkg.tar.gz" % ( \
                self.scope['pkgname'],
                self.scope['pkgver'],
                self.scope['pkgrel'],
                self.scope['arch'][0]
        )

if __name__ == "__main__":
    import sys
    PkgBuild(sys.argv[1])
