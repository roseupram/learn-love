#!/bin/bash
set -e
Release_dir="$HOME/desktop"

# remove debug
sed -i.bak /^[^-].*lldebug/s/^/--/ main.lua
# build a fullscreen game
sed -i.bak /fullscreen/s/false/true/ conf.lua
mkdir -p "$Release_dir"
zip "$Release_dir/game.love" -r * -x release 
mv -f conf.lua.bak conf.lua
