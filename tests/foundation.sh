#!/bin/sh
set -eu

binary=${1:-./build/hollow-grid-asm}
port=${HG_TEST_PORT:-18793}
log=$(mktemp)
data=$(mktemp -d)

"$binary" --addr "127.0.0.1:$port" --data "$data" >"$log" 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; rm -f "$log"; rm -rf "$data"' EXIT

attempt=0
while [ "$attempt" -lt 50 ]; do
  if body=$(curl -fsS "http://127.0.0.1:$port/health" 2>/dev/null); then
    break
  fi
  attempt=$((attempt + 1))
  sleep 0.1
done

test "${body:-}" != ""
printf '%s' "$body" | grep -q '"ok":true'
printf '%s' "$body" | grep -q '"world":"Basalt Relay"'

deep=$(curl -fsS "http://127.0.0.1:$port/health/deep")
printf '%s' "$deep" | grep -q '"critical":true'
printf '%s' "$deep" | grep -q '"grid_hub"'

map=$(curl -fsS "http://127.0.0.1:$port/map.svg")
printf '%s' "$map" | grep -q 'Basalt Relay'

python3 ./tests/ws_persistence.py "$port" "$data"
python3 ./tests/ws_gameplay.py "$port"

printf '%s\n' "foundation checks passed"

