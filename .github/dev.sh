#!/usr/bin/env bash
set -Eeuo pipefail

open_browser() {
	sleep 2
	xdg-open http://localhost:8000/
}

cd .github/dist
open_browser &
exec python3 -m http.server
