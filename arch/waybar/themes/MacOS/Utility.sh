#!/bin/bash
S="$HOME/.config/waybar/scripts"
K_D="$HOME/.config/kitty/kitty.conf"
R_D="$HOME/.config/rofi/config.rasi"

upd() {
    [ -f "$1" ] || return 1
    rm -f "$2.bak"
    [ -f "$2" ] && mv "$2" "$2.bak"
    cp "$1" "$2"
}

upd "$S/kitty-minmal.conf" "$K_D"
upd "$S/rofi-minmal.rasi" "$R_D"
