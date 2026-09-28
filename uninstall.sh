#!/usr/bin/env bash
# xd'yi kaldirir. Kayitli klasorler (aliases dosyasi) korunur.
set -euo pipefail

install_file="${XDG_DATA_HOME:-$HOME/.local/share}/xd/xd.sh"
marker_begin='# >>> xd >>>'
marker_end='# <<< xd <<<'

for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc_file" ] && grep -qF "$marker_begin" "$rc_file"; then
        temporary_file="$rc_file.xd.$$.tmp"
        awk -v begin="$marker_begin" -v end="$marker_end" '
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            !skip { print }
        ' "$rc_file" > "$temporary_file"
        cat "$temporary_file" > "$rc_file"
        rm -f -- "$temporary_file"
        echo "Temizlendi: $rc_file"
    fi
done

if [ -f "$install_file" ]; then
    rm -f -- "$install_file"
    echo 'xd kaldirildi. Kayitli klasorler korunmustur.'
else
    echo 'xd kurulu degil.'
fi
