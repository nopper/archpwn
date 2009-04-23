#!/bin/sh
cd ../pacman-repo/packages/

for i in *; do
    rm -f /var/cache/pacman/pkg/$i
done
