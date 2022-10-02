#!/usr/bin/env bash

# Change the grep pattern to match your keyboard and trackpad names. 
keyboard=$(xinput list | grep "Razer Razer Blade" | sed 's/^.*=//g' | awk '{ print $1 }' | sort -r | head -n1)
trackpad=$(xinput list | grep "ELAN0406:00 04F3:30A6 Touchpad" | sed 's/^.*=//g' | awk '{ print $1 }')

if [ "$1" = "enable" ]; then
    xinput enable $keyboard
    xinput enable $trackpad
    exit 0
fi

if [ "$1" = "disable" ]; then
    xinput disable $keyboard
    xinput disable $trackpad
    exit 0
fi

if [ "$1" = "status" ]; then
    xinput list-props $keyboard | grep "Device Enabled" | grep -q 1 && echo "Keyboard: Enabled" || echo "Keyboard: Disabled"
    xinput list-props $trackpad | grep "Device Enabled" | grep -q 1 && echo "Trackpad: Enabled" || echo "Trackpad: Disabled"
    exit 0
fi

if [ "$1" = "help" ]; then
    echo "Usage: input.sh [enable|disable|status|help]"
    exit 0
fi

if [ -n "$(lsusb | grep "ZSA Technology Labs Moonlander Mark I")" ]; then
    if xinput list-props $keyboard | grep "Device Enabled" | grep -q 1; then
        xinput disable $keyboard
    else
        xinput enable $keyboard
    fi
fi

if [ -n "$(lsusb | grep "Logitech, Inc. Unifying Receiver")" ] || [ -n "$(lsusb | grep "PloopyCo Mouse")" ]; then
    if xinput list-props $trackpad | grep "Device Enabled" | grep -q 1; then
        xinput disable $trackpad
    else
        xinput enable $trackpad
    fi
fi
