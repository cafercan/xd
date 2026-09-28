#!/usr/bin/env bash
# xd'yi Linux/macOS icin kurar: xd.sh'yi kopyalar ve shell rc dosyalarina ekler.
set -euo pipefail

source_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_directory="${XDG_DATA_HOME:-$HOME/.local/share}/xd"
install_file="$install_directory/xd.sh"
marker_begin='# >>> xd >>>'
marker_end='# <<< xd <<<'

mkdir -p -- "$install_directory"
cp -f -- "$source_directory/xd.sh" "$install_file"

add_to_rc() {
    local rc_file=$1
    if [ -f "$rc_file" ] && grep -qF "$marker_begin" "$rc_file"; then
        echo "Zaten ekli: $rc_file"
        return
    fi
    {
        echo
        echo "$marker_begin"
        echo "[ -f \"$install_file\" ] && . \"$install_file\""
        echo "$marker_end"
    } >> "$rc_file"
    echo "Eklendi: $rc_file"
}

added=0
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ]; then
        add_to_rc "$rc_file"
        added=1
    fi
done
if [ "$added" -eq 0 ]; then
    add_to_rc "$HOME/.bashrc"
fi

echo "xd kuruldu: $install_file"
echo "Yeni bir terminal acin veya su komutu calistirin: source \"$install_file\""
echo "Ornek: xd -add proje ~/Workspaces/proje"
