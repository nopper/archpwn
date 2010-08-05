#!/bin/bash
# Simple script to update archpwn database

cd "$(dirname $0)/../pacman/pkg"
echo "Regenating archpwn database inside $(pwd)"

rm archpwn.*
repo-add archpwn.db.tar.gz *.pkg.tar.xz > /dev/null 2>&1
echo "Done"
