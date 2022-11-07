#!/usr/bin/env bash

# we are creating a script that will run at after login that will ask if the user wants to run other scripts

read -p "Enter the desired brightness level (0-100): " -n 3 -r

if [[ $REPLY =~ ^[0-9]{1,3}$ ]]; then
  sudo ddcutil setvcp 10 $REPLY # for external monitor
  qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl setBrightness $REPLY # for laptop screen
  echo "Brightness set to $REPLY"
fi

read -p "Do you want to disable the internal keyboard and trackpad? (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
  /home/$(whoami)/git/scripts/input.sh disable
  echo "Trackpad and Keyboard disabled"
else
  /home/$(whoami)/git/scripts/input.sh enable
  echo "Trackpad and Keyboard enabled"
fi
