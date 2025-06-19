#! /bin/bash
# perl -ep 's/^require*lldebug)/#\1/' main.lua
if [ "$1" == 'debug' ]; then
	echo 'debug'
	# delete -- and spaces
	perl -i.bak -pe 's/^--\s*// if /^--.*require.*debug/' main.lua
else
	echo 'run'
	# comment
	perl -i.bak -pe 's/^/-- / if /^require.*debug/' main.lua
	# perl -i.bak -pe 's/(.*)/-- \1/ if /^require.*debug/' main.lua
fi
cmd='love'
if ! type $cmd &>/dev/null ;then
	echo $cmd not found!
	return 1
fi
$cmd .
