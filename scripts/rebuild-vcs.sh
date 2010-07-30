#!/bin/bash
# Simple script to rebuild all -svn, -git, -hg packages
# present in archpwn repository.

LIVEPACKAGES=('metasploit3' 'exploit-tree' 'milw0rm-archive' 'exploit-db')

rebuild() {
    local path=$(dirname $1)
    local srcdir=$2
    local pkgdir=$3

    echo "Rebuilding $pkgdir ..."
    pkg-builder $path $srcdir $pkgdir
}

find_pkgs() {
    local path=$1
    local srcdir=$2
    local pkgdir=$3

    for file in $(find $path -maxdepth 3 -name "PKGBUILD"); do
        if [ "$(grep '^pkgname=.*-\(svn\|git\|hg\)$' $file)" != "" ]; then
            rebuild $file $srcdir $pkgdir
        else
            pkgname=$(grep "^pkgname=.*$" $file | sed -e 's/pkgname=//')

            for i in ${LIVEPACKAGES[@]}; do
                if [ "$pkgname" == $i ]; then
                    rebuild $file $srcdir $pkgdir
                fi
            done
        fi
    done
}

if [ $# -ne 3 ]; then
    echo "Usage: $0 <repodir> <srcdir> <pkgdir>"
else
    find_pkgs $1 $2 $3
fi
