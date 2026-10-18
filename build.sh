#!/usr/bin/env bash
# Pack this kit into ONE self-extracting file: dist/mac-setup.sh
# On another Mac:  bash mac-setup.sh [--dry-run]
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
OUT="$KIT/dist/mac-setup.sh"
mkdir -p "$KIT/dist"

cat > "$OUT" <<'HEADER'
#!/usr/bin/env bash
# Self-extracting mac-setup kit. Run:  bash mac-setup.sh [--dry-run]
# It unpacks the kit into a temp folder and runs its install.sh with your options.
set -euo pipefail
DIR="$(mktemp -d -t mac-setup)"
trap 'rm -rf "$DIR"' EXIT
LINE=$(awk '/^__PAYLOAD_BELOW__$/ { print NR + 1; exit }' "$0")
tail -n +"$LINE" "$0" | base64 -D | tar -xzf - -C "$DIR"
cd "$DIR/kit"
./install.sh "$@"   # no exec: the EXIT trap must still delete the temp folder
exit $?
__PAYLOAD_BELOW__
HEADER

# base64 keeps the file plain text, so mail, chat or AirDrop can't break it.
COPYFILE_DISABLE=1 tar -czf - -C "$KIT" -s '|^\.|kit|' \
  --exclude './dist' --exclude './.git' --exclude '.DS_Store' . \
  | base64 -b 76 >> "$OUT"

chmod +x "$OUT"
echo "built: $OUT ($(du -h "$OUT" | cut -f1))"
