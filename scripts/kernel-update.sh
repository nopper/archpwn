#!/bin/sh
rm -rf ../repo/regen-modules/*
echo "1) Linux Kernel modules skeleton regen"
./module-rebuild -a ../repo/lkm-skel/ ../repo/regen-modules/
echo "2) Regen LKM from abs tree"
./module-rebuild /var/abs/ ../repo/regen-modules/
echo "3) Building all"
./pkg-builder -d -f ../repo/regen-modules/ ../pacman-repo/sources/ ../pacman-repo/packages/
