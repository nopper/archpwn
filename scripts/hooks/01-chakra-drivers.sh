#!/bin/bash
# Simple hook to generate drivers lzm archive containing
# all proprietary drivers coming from nvidia and ati.

DRIVERS=('nvidia' 'catalyst')
HW_DRIVER_PATH="/opt/chakra/pkgs"

run_hook() {
    local destination="$HOOK_WDIR/drivers/$HW_DRIVER_PATH"
    mkdir -p "$destination"

    for driver in ${DRIVERS[@]}; do
        info "Copying $driver ..."
        cp "$PACMAN_PKG/$driver-"*"-$ARCH.pkg.tar.xz" "$destination/"
    done

    info "Generating non-free-drivers.lzm ..."
    mksquashfs "$HOOK_WDIR"/drivers/opt/ "$HOOK_WDIR"/non-free-drivers.lzm -keep-as-directory -noappend

    info "Installing under modules/"
    mv "$HOOK_WDIR"/non-free-drivers.lzm "$IMGROOT/$CDNAME"/modules/
}
