#!/usr/bin/env bash
set -euo pipefail

# Keep test-only npm dependencies out of the linked extension directory.
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/pi-extensions/full-compact" "$work/tests"
cp "$root"/pi-extensions/full-compact/*.ts "$work/pi-extensions/full-compact/"
cp "$root/tests/full-compact.test.ts" "$work/tests/"
cd "$work"
printf '{"private":true,"type":"module"}\n' > package.json
npm install --ignore-scripts --no-audit --no-fund @earendil-works/pi-coding-agent@1.0.0 typescript@5.9.3 tsx@4.20.6 >/dev/null
./node_modules/.bin/tsc --noEmit --module nodenext --moduleResolution nodenext --target es2023 \
  --allowImportingTsExtensions --skipLibCheck --strict pi-extensions/full-compact/*.ts tests/full-compact.test.ts
./node_modules/.bin/tsx --test tests/full-compact.test.ts
