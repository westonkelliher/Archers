#!/bin/bash
# Host a room from this machine instead of from somebody's browser tab: steadier
# for everyone. Start it BEFORE anyone opens the room's link, stop with Ctrl-C.
#   ./host.sh [room] [server]
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/bin/godot-4.4.1.bak}"
room="${1:-tonight}"
server="${2:-wss://weston.pub}"
echo "https://weston.pub/archers/?room=$room"
while true; do
	"$GODOT" --headless --audio-driver Dummy -- --dedicated --room="$room" --server="$server" 2>&1 | grep --line-buffered "dedicated host"
	sleep 2
done
