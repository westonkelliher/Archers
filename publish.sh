#!/bin/bash
set -e

gn="/home/weston/dev/GameNite"
g_dir="$gn/games/archers/game"

echo "MAKE SURE YOU BUILD BEFORE YOU EXECUTE THIS"


cp build/* $g_dir/
rm -r $g_dir/controller
cp -r controlpad_test_server/controller $g_dir/

cd $gn
./bin/gcp-upload.sh archers games/archers

