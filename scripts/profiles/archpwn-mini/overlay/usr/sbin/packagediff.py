#!/usr/bin/env python

import sys

def parse_file(filename):
    list = []
    file = open(filename)
    for line in file:
        pkgname, pkgver = line.split()
        list.append({'name':pkgname, 'version':pkgver})

    return list


def find_by_name(name, list):
    for entry in list:
        if entry['name'] == name:
            list.remove(entry)
            return entry

    return None


if len(sys.argv) != 3:
    print "Usage: %s <oldpackagelist> <newpackagelist>" % sys.argv[0]
    sys.exit(1)

pkgs_old = parse_file(sys.argv[1])
pkgs_new = parse_file(sys.argv[2])

list_updated = []
list_new = []

for pkg in pkgs_new:
    oldpkg = find_by_name(pkg['name'], pkgs_old)

    if oldpkg == None:
        list_new.append({'name': pkg['name']})
    else:
        if pkg['version'] != oldpkg['version']:
            list_updated.append({ 'name':pkg['name'], 'aux' : '%s -> %s' % (oldpkg['version'], pkg['version']) })

if len(list_new) > 0:
    print "Additions"
    for entry in list_new:
        print entry['name']

if len(pkgs_old) > 0:
    print "\nRemovals"
    for entry in pkgs_old:
        print entry['name']

if len(list_updated):
    print "\nUpdates"
    for entry in list_updated:
        print "%s %s" % (entry['name'], entry['aux'])
