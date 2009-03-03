#!/bin/sh
# /opt/chakra/pkgs
drivers="nvidia-173xx nvidia-96xx nvidia nvidia-utils catalyst"

if [ "$1" = "download" ]; then
    echo ">> Downloading drivers:"
    for driver in $drivers; do
        # All packages are in extra so:
        wget -Nc "http://mir.archlinux.fr/extra/os/i686/$driver-$(pacman -sS "^$driver$" | head -n 1 | awk -F" "  '{print $2}')-i686.pkg.tar.gz"
    done
elif [ "$1" = "pack" ]; then
    rm -rf temp/
    mkdir -p temp/opt/chakra/pkgs/

    for driver in $drivers; do
        cp $driver-$(pacman -sS "^$driver$" | head -n 1 | awk -F" "  '{print $2}')-i686.pkg.tar.gz \
           temp/opt/chakra/pkgs/
    done

    echo ">> Packing drivers:"
    ls -1 temp/opt/chakra/pkgs/

    mksquashfs temp/ nonfree-drivers.lzm -noappend
    chmod 0444 nonfree-drivers.lzm

    echo ">> Moving to packages."
    mv nonfree-drivers.lzm ../packages/

    echo ">> Removing temp directory"
    rm -rf temp/
fi
