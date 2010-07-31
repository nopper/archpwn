#!/bin/bash
# Simple script to generate shortcuts for applications
# TODO: check package list

run_hook() {
    info "Building shortcuts (this may take few minutes) ..."
    desktop-gen -s 1 -o "$IMGROOT/$CDNAME"/modules/shortcuts.lzm "$PACMAN_PKG"

    if [ $? -ne 0 ]; then
        warn "Something went wrong!"
    else
        info "Shortcuts created succefully."
    fi
}
