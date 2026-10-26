#!/usr/bin/env bash
# install.sh / uninstall.sh testleri: hangi baslangic dosyasina yazildigini gecici bir
# HOME'da dener. macOS davranisi XD_TEST_OS=Darwin ile Linux'ta da denenebilir.
# Kullanim: bash tests/install.test.sh
set -u

repo=$(cd -- "$(dirname -- "$0")/.." && pwd)
marker='# >>> xd >>>'
failures=0

fail() {
    printf 'HATA [%s]: %s\n' "$scenario" "$*" >&2
    failures=$((failures + 1))
}

# run <senaryo> <os> <shell> <onceden olusturulacak dosyalar...>
run() {
    scenario=$1 os=$2 shell=$3
    shift 3
    home=$(mktemp -d)
    local f
    for f in "$@"; do : > "$home/$f"; done
    HOME=$home XDG_DATA_HOME= SHELL=/bin/$shell XD_TEST_OS=$os bash "$repo/install.sh" >/dev/null || fail 'install.sh basarisiz'
    [ -f "$home/.local/share/xd/xd.sh" ] || fail 'xd.sh kopyalanmadi'
}

has_block() { grep -qF "$marker" "$home/$1" 2>/dev/null; }
expect() { has_block "$1" || fail "$1 dosyasina eklenmedi"; }
expect_not() { ! has_block "$1" || fail "$1 dosyasina eklenmemeliydi"; }
done_with() { rm -rf -- "$home"; }

run 'macOS, yeni hesap (zsh, hic rc yok)' Darwin zsh
expect .zshrc; expect_not .bashrc; expect_not .bash_profile
done_with

run 'macOS, bash kullanicisi, hic rc yok' Darwin bash
expect .zshrc; expect .bash_profile; expect_not .bashrc
done_with

run 'macOS, ~/.profile var' Darwin bash .profile
expect .profile; expect_not .bash_profile
done_with

run 'macOS, ~/.bash_profile ve ~/.bashrc var' Darwin zsh .bash_profile .bashrc
expect .zshrc; expect .bash_profile; expect .bashrc
done_with

run 'Linux, hic rc yok, bash' Linux bash
expect .bashrc; expect_not .zshrc
done_with

run 'Linux, hic rc yok, zsh' Linux zsh
expect .zshrc; expect_not .bashrc
done_with

run 'Linux, iki rc de var' Linux bash .bashrc .zshrc
expect .bashrc; expect .zshrc; expect_not .bash_profile
done_with

run 'iki kez kurulum ayni blogu tekrar eklemez' Darwin zsh
HOME=$home XDG_DATA_HOME= SHELL=/bin/zsh XD_TEST_OS=Darwin bash "$repo/install.sh" >/dev/null
[ "$(grep -cF "$marker" "$home/.zshrc")" -eq 1 ] || fail 'blok iki kez eklendi'
done_with

run 'kaldirma tum dosyalari temizler' Darwin bash .profile .bashrc .zshrc
HOME=$home XDG_DATA_HOME= bash "$repo/uninstall.sh" >/dev/null || fail 'uninstall.sh basarisiz'
for f in .profile .bashrc .zshrc .bash_profile; do ! has_block $f || fail "$f temizlenmedi"; done
[ ! -f "$home/.local/share/xd/xd.sh" ] || fail 'xd.sh silinmedi'
done_with

if [ "$failures" -ne 0 ]; then
    echo "$failures hata" >&2
    exit 1
fi
echo 'install testleri gecti'
