Release_dir="$HOME/desktop"
# mkdir -p "$Release_dir"

zip "release/game.love" -r * -x release 
cp "release/game.love" "$Release_dir/"  
