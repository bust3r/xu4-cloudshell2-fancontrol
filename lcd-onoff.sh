#!/bin/bash
# Turn ODROID LCD on or off with a shell whiptail GUI
# REF: https://forum.odroid.com/viewtopic.php?f=97&t=16425

# Make sure we run with root privileges
if [[ $UID != 0 ]]; then
        # not root, use sudo
        echo "This script needs root privileges, rerunning it now using sudo!"
        sudo "${SHELL}" "$0" $*
        exit $?
fi
# get real username
if [[ $UID = 0 ]] && [[ ! -z "$SUDO_USER" ]]; then
        USER="$SUDO_USER"
else
        USER="$(whoami)"
fi

if (whiptail --yesno "This will turn on and off the LCD" --fb --yes-button ON --no-button OFF 10 60 1); then
        echo 0 > /sys/class/backlight/*/bl_power
else
        echo 1 > /sys/class/backlight/*/bl_power
fi