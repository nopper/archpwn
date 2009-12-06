#!/bin/bash
# ---------------------------------------------------
# Script to create bootable ISO in Linux
# usage: make_iso.sh [ /tmp/slack2go.iso ]
# author: Tomas M. <http://www.linux-live.org>
# ---------------------------------------------------

if [ "$1" = "--help" -o "$1" = "-h" ]; then
  echo "This script will create bootable ISO from files in curent directory."
  echo "Current directory must be writable."
  echo "example: $0 /mnt/sda2/arch.iso"
  exit
fi

CDLABEL="ArchPwn"
ISONAME="$1"

cd $(dirname $0)

if [ "$ISONAME" = "" ]; then
   SUGGEST=$(readlink -f ../../$(basename $(pwd)).iso)
   echo -ne "Target ISO file name [ Hit enter for $SUGGEST ]: "
   read ISONAME
   if [ "$ISONAME" = "" ]; then ISONAME="$SUGGEST"; fi
fi

mkisofs -o "$ISONAME" -v -J -R -D -publisher "http://www.archpwn.org" -p "Francesco Piccinno" -A "$CDLABEL" -V "$CDLABEL" \
-no-emul-boot -boot-info-table -boot-load-size 4 \
-b boot/isolinux/isolinux.bin -c boot/isolinux/isolinux.boot .

md5sum $1 > $1.md5
