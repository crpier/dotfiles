#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/pi-extensions/auto-name" "$work/tests"
cp "$root/pi-extensions/auto-name/index.ts" "$work/pi-extensions/auto-name/"
cp "$root/tests/auto-name.test.ts" "$work/tests/"
cd "$work"
printf '{"private":true,"type":"module"}\n' > package.json
npm install --ignore-scripts --no-audit --no-fund @earendil-works/pi-coding-agent@1.0.0 typescript@5.9.3 tsx@4.20.6 >/dev/null
./node_modules/.bin/tsc --noEmit --module nodenext --moduleResolution nodenext --target es2023 \
  --allowImportingTsExtensions --skipLibCheck --strict pi-extensions/auto-name/index.ts tests/auto-name.test.ts
./node_modules/.bin/tsx --test tests/auto-name.test.ts
