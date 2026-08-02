#!/bin/bash
# Export the Godot web build into public/ and prep it for Cloudflare
# (wasm must be stored gzipped to fit the 25MiB asset limit; the worker
# serves it back with Content-Encoding: gzip).
set -e
cd "$(dirname "$0")/.."
godot --headless --export-release "Web" web/public/index.html
gzip -9 -f web/public/index.wasm
echo "build ready; deploy with: cd web && npx wrangler deploy"
