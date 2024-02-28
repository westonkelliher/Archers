#!/bin/sh
echo -ne '\033c\033]0;Archers\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Archers.x86_64" "$@"
