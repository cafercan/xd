#!/usr/bin/env bash
# xd.sh testleri. Kullanim: bash tests/xd.test.sh  (veya: zsh tests/xd.test.sh)

test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
export XD_DATA_FILE="$test_root/data/aliases"
destination="$test_root/destination with space"
mkdir -p -- "$destination"
original_location=$PWD

. "$(cd -- "$(dirname -- "$0")/.." && pwd)/xd.sh"

fail() {
    printf 'HATA: %s\n' "$*" >&2
    exit 1
}

xd -add GDRS "$destination" >/dev/null || fail 'xd -add basarisiz.'
[ -f "$XD_DATA_FILE" ] || fail 'Kayit dosyasi olusturulmadi.'

xd gdrs || fail 'xd gdrs basarisiz.'
[ "$PWD" = "$destination" ] || fail 'xd kayitli klasore gecemedi.'

listed=$(xd -list)
[ "$(printf '%s\n' "$listed" | grep -c 'GDRS')" -eq 1 ] || fail 'xd -list beklenen kaydi dondurmedi.'

cd -- "$destination"
xd -atf GDMP >/dev/null || fail 'xd -atf basarisiz.'
xd -pwd GDMP2 >/dev/null || fail 'xd -pwd basarisiz.'

cd -- "$original_location"
xd gdmp && [ "$PWD" = "$destination" ] || fail 'xd -atf bulunulan klasoru kaydedemedi.'

cd -- "$original_location"
xd gdmp2 && [ "$PWD" = "$destination" ] || fail 'xd -pwd bulunulan klasoru kaydedemedi.'

xd -add gdrs "$test_root" >/dev/null || fail 'xd -add guncelleme basarisiz.'
[ "$(wc -l < "$XD_DATA_FILE")" -eq 3 ] || fail 'xd -add ayni adi iki kez kaydetti.'
[ "$(_xd_lookup GDRS)" = "$test_root" ] || fail 'xd -add kaydi guncellemedi.'

xd -o kayitli-olmayan-ad 2>/dev/null && fail 'xd -o bilinmeyen kayit icin hata vermedi.'
xd kayitli-olmayan-ad 2>/dev/null && fail 'xd bilinmeyen kayit icin hata vermedi.'
xd -add yok "$test_root/yok" 2>/dev/null && fail 'xd -add olmayan klasor icin hata vermedi.'

xd -remove gdmp >/dev/null || fail 'xd -remove gdmp basarisiz.'
xd -remove gdmp2 >/dev/null || fail 'xd -remove gdmp2 basarisiz.'
xd -remove gdrs >/dev/null || fail 'xd -remove gdrs basarisiz.'
[ "$(xd -list)" = 'Henuz kayitli klasor yok.' ] || fail 'xd -remove kaydi silemedi.'

cd -- "$original_location"
echo 'Tum xd testleri basarili.'
