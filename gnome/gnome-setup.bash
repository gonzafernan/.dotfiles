#!/bin/bash

echo "GNOME environment setup"
echo "GNOME terminal setup"
cat ./terminal/gnome-terminal.properties | dconf load /org/gnome/terminal/
