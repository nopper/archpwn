#/bin/sh

if [ "$1" = "" ]; then
  echo "This script will create bootable ISO from files in curent directory."
  echo "Current directory must be writable."
  echo "example: $0 /mnt/hda5/livecd.iso"
fi


ISONAME="$1"
#. /usr/lib/liblinuxlive

#./core.sh

if [ "$ISONAME" = "" ]; then
   SUGGEST=$(readlink -f ../$(basename $(pwd)).iso)
   echo -ne "Target ISO file name [ Hit enter for $SUGGEST ]: "
   read ISONAME
   if [ "$ISONAME" = "" ]; then ISONAME="$SUGGEST"; fi
fi

mkisofs -r -l -b "boot/grub/stage2_eltorito" -uid 0 -gid 0 \
   -no-emul-boot -boot-load-size 4 -boot-info-table \
   -publisher "Arch Linux <archlinux.org>" \
   -input-charset=UTF-8 -p "prepared by $NAME" \
   -A "Arch Linux Live/Rescue CD" \
   -o "$ISONAME" "$(pwd)"

md5sum $1 > $1.md5