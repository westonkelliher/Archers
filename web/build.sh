#!/bin/bash
# Export the game for the web into web/public/archers. Needs Godot 4.4.x with
# the web export templates installed.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/bin/godot-4.4.1.bak}"
out=web/public/archers
tmp=web/.export # wrangler chokes if the 40MB wasm ever shows up in public/

rm -rf $tmp && mkdir -p $tmp
"$GODOT" --headless --import > /dev/null 2>&1 || true
"$GODOT" --headless --export-release Web $tmp/index.html
# a Workers static asset tops out at 25 MiB; shell.html inflates this on load
gzip -9 -c $tmp/index.wasm > $tmp/index.wasm.gzbin
rm $tmp/index.wasm
rm -f $out/index.*
mv $tmp/index.* $out/
rm -rf $tmp
ls -la $out
