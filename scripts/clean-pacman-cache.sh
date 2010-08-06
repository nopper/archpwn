#!/bin/sh
cd ../pacman/pkg/

for i in *; do
    rm -f /var/cache/pacman/pkg/$i
done
