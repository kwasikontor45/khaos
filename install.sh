#!/bin/bash
set -e

KHAOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

cp "$KHAOS_DIR/arc" "$BIN_DIR/arc"
cp "$KHAOS_DIR/lt"  "$BIN_DIR/lt"
chmod +x "$BIN_DIR/arc" "$BIN_DIR/lt"

# ensure ~/.local/bin is in PATH
detect_rc() {
  if [[ -n "$ZDOTDIR" && -f "$ZDOTDIR/.zshrc" ]]; then echo "$ZDOTDIR/.zshrc"
  elif [[ -f "$HOME/.zshrc" ]]; then echo "$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.bash_profile" ]]; then echo "$HOME/.bash_profile"
  else echo ""
  fi
}

SHELL_RC="$(detect_rc)"

if [[ -n "$SHELL_RC" ]] && ! grep -qF '.local/bin' "$SHELL_RC" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$SHELL_RC"
  echo "  patched PATH in $SHELL_RC"
fi

echo ""
echo "  khaos installed"
echo "  arc  →  $BIN_DIR/arc"
echo "  lt   →  $BIN_DIR/lt"
echo ""
echo "  the clone can now be deleted:  rm -rf $KHAOS_DIR"
echo ""
if [[ -n "$SHELL_RC" ]]; then
  echo "  reload:  source $SHELL_RC"
fi
echo ""
