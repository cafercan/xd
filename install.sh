#!/usr/bin/env bash
# xd'yi Linux/macOS icin kurar: xd.sh'yi kopyalar ve shell baslangic dosyalarina ekler.
set -euo pipefail

source_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install_directory="${XDG_DATA_HOME:-$HOME/.local/share}/xd"
install_file="$install_directory/xd.sh"
marker_begin='# >>> xd >>>'
marker_end='# <<< xd <<<'
# XD_TEST_OS yalnizca testler icindir (macOS davranisini Linux'ta denemek)
os=${XD_TEST_OS:-$(uname -s)}
login_shell=$(basename -- "${SHELL:-}")

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

targets=()
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc_file" ] && targets+=("$rc_file")
done

if [ "$os" = Darwin ]; then
    # macOS'ta varsayilan kabuk zsh, ama yeni bir hesapta ~/.zshrc hic yoktur
    [ -f "$HOME/.zshrc" ] || targets+=("$HOME/.zshrc")
    # Terminal uygulamasi bash'i login shell olarak acar: ~/.bashrc degil, sirayla
    # ~/.bash_profile, ~/.bash_login, ~/.profile'dan ilk bulunani okur. Olmayan bir
    # ~/.bash_profile olusturmak ~/.profile'in okunmasini engellerdi.
    if [ -f "$HOME/.bash_profile" ]; then
        targets+=("$HOME/.bash_profile")
    elif [ -f "$HOME/.bash_login" ]; then
        targets+=("$HOME/.bash_login")
    elif [ -f "$HOME/.profile" ]; then
        targets+=("$HOME/.profile")
    elif [ "$login_shell" = bash ]; then
        targets+=("$HOME/.bash_profile")
    fi
elif [ ${#targets[@]} -eq 0 ]; then
    if [ "$login_shell" = zsh ]; then
        targets+=("$HOME/.zshrc")
    else
        targets+=("$HOME/.bashrc")
    fi
fi

for rc_file in "${targets[@]}"; do
    add_to_rc "$rc_file"
done

echo "xd kuruldu: $install_file"
echo "Yeni bir terminal acin veya su komutu calistirin: source \"$install_file\""
echo "Ornek: xd -add proje ~/Workspaces/proje"
