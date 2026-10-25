#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/opc"

if [ $# -gt 0 ]; then
  dest=$1
elif [ "$(id -u)" -eq 0 ] && [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  dest=/usr/local/bin
else
  dest=$HOME/.local/bin
fi

[ -f "$src" ] || { echo "missing $src" >&2; exit 1; }
mkdir -p "$dest"
install -m 755 "$src" "$dest/opc"

echo "installed $dest/opc"
case ":$PATH:" in
  *":$dest:"*) ;;
  *)
    echo "note: $dest is not on your PATH" >&2
    case "${SHELL##*/}" in
      zsh) echo "  echo 'export PATH=\"$dest:\$PATH\"' >> ~/.zshrc && source ~/.zshrc" >&2 ;;
      *) echo "  echo 'export PATH=\"$dest:\$PATH\"' >> ~/.bashrc && source ~/.bashrc" >&2 ;;
    esac
    ;;
esac
