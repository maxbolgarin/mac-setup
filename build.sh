#!/usr/bin/env bash
# Pack this kit into self-extracting single files:
#   dist/mac-setup.sh            full kit       bash mac-setup.sh [--dry-run]
#   dist/mac-setup-terminal.sh   terminal only  bash mac-setup-terminal.sh [--dry-run]
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$KIT/dist"

# build <output name> <option always passed to install.sh, or ""> [paths to leave out...]
build() {
  local name="$1" out="$KIT/dist/$1" fixed="$2"; shift 2
  local excludes=(--exclude './dist' --exclude './.git' --exclude '.DS_Store')
  local p; for p in "$@"; do excludes+=(--exclude "./$p"); done

  cat > "$out" <<HEADER
#!/usr/bin/env bash
# Self-extracting mac-setup kit ($name). Run:  bash $name [--dry-run]
# It unpacks the kit into a temp folder and runs its install.sh with your options.
set -euo pipefail
DIR="\$(mktemp -d -t mac-setup)"
trap 'rm -rf "\$DIR"' EXIT
LINE=\$(awk '/^__PAYLOAD_BELOW__\$/ { print NR + 1; exit }' "\$0")
tail -n +"\$LINE" "\$0" | base64 -D | tar -xzf - -C "\$DIR"
cd "\$DIR/kit"
./install.sh $fixed "\$@"   # no exec: the EXIT trap must still delete the temp folder
exit \$?
__PAYLOAD_BELOW__
HEADER

  # base64 keeps the file plain text, so mail, chat or AirDrop can't break it.
  COPYFILE_DISABLE=1 tar -czf - -C "$KIT" -s '|^\.|kit|' "${excludes[@]}" . \
    | base64 -b 76 >> "$out"
  chmod +x "$out"
  echo "built: $out ($(du -h "$out" | cut -f1 | tr -d ' '))"
}

build mac-setup.sh ""
build mac-setup-terminal.sh "--terminal" Brewfile vscode
