#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/opc"
dest="${1:-$HOME/.local/bin}"

[ -f "$src" ] || { echo "missing $src" >&2; exit 1; }
mkdir -p "$dest"
install -m 755 "$src" "$dest/opc"

echo "installed $dest/opc"
case ":$PATH:" in
  *":$dest:"*) ;;
  *) echo "note: $dest is not on your PATH" >&2 ;;
esac
