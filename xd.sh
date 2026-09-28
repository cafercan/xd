# xd - kalici klasor kisayollari (bash / zsh)
#
# Bu dosya calistirilmaz, shell'e "source" edilir:
#   source /yol/xd.sh
#
# Kayitlar varsayilan olarak ${XDG_DATA_HOME:-~/.local/share}/xd/aliases
# dosyasinda "ad<TAB>yol" satirlari olarak tutulur. XD_DATA_FILE ile degistirilebilir.

_xd_data_file() {
    if [ -n "${XD_DATA_FILE:-}" ]; then
        printf '%s\n' "$XD_DATA_FILE"
    else
        printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/xd/aliases"
    fi
}

_xd_error() {
    printf 'xd: %s\n' "$*" >&2
}

# Adin kayitli yolunu yazar. Ad buyuk/kucuk harfe duyarli degildir.
_xd_lookup() {
    local data_file
    data_file=$(_xd_data_file)
    [ -f "$data_file" ] || return 1
    XD_KEY=$1 awk -F '\t' '
        BEGIN { key = tolower(ENVIRON["XD_KEY"]) }
        tolower($1) == key { print $2; found = 1; exit }
        END { exit !found }
    ' "$data_file"
}

# Kaydi ekler veya gunceller (yeni yol bos ise siler). Sira korunur.
_xd_write() {
    local data_file temporary_file
    data_file=$(_xd_data_file)
    temporary_file="$data_file.$$.tmp"
    mkdir -p -- "$(dirname -- "$data_file")" || return 1
    [ -f "$data_file" ] || : > "$data_file" || return 1

    if XD_KEY=$1 XD_VALUE=$2 awk -F '\t' '
        BEGIN { key = tolower(ENVIRON["XD_KEY"]); value = ENVIRON["XD_VALUE"] }
        tolower($1) == key {
            if (value != "" && !done) print ENVIRON["XD_KEY"] "\t" value
            done = 1
            next
        }
        { print }
        END { if (!done && value != "") print ENVIRON["XD_KEY"] "\t" value }
    ' "$data_file" > "$temporary_file"; then
        mv -f -- "$temporary_file" "$data_file"
    else
        rm -f -- "$temporary_file"
        _xd_error "kayit dosyasi yazilamadi: $data_file"
        return 1
    fi
}

_xd_validate_name() {
    local tab
    tab=$(printf '\t')
    case "$1" in
        '') _xd_error 'ad bos olamaz.'; return 1 ;;
        -*) _xd_error "ad '-' ile baslayamaz: $1"; return 1 ;;
        *"$tab"* | *'
'*) _xd_error 'ad sekme veya satir sonu iceremez.'; return 1 ;;
    esac
}

_xd_save() {
    local name=$1 target=$2 tab
    _xd_validate_name "$name" || return 1
    tab=$(printf '\t')
    case "$target" in
        *"$tab"* | *'
'*) _xd_error 'yol sekme veya satir sonu iceremez.'; return 1 ;;
    esac
    _xd_write "$name" "$target" || return 1
    printf 'Kaydedildi: %s -> %s\n' "$name" "$target"
}

_xd_resolve() {
    local destination
    if ! destination=$(_xd_lookup "$1"); then
        _xd_error "Kayit bulunamadi: $1. Kayitlari gormek icin 'xd -list' yazin."
        return 1
    fi
    if [ ! -d "$destination" ]; then
        _xd_error "'$1' icin kayitli klasor artik bulunamiyor: $destination"
        return 1
    fi
    printf '%s\n' "$destination"
}

_xd_open() {
    local opener
    for opener in xdg-open open; do
        if command -v "$opener" >/dev/null 2>&1; then
            ("$opener" "$1" >/dev/null 2>&1 &)
            return 0
        fi
    done
    if command -v gio >/dev/null 2>&1; then
        (gio open "$1" >/dev/null 2>&1 &)
        return 0
    fi
    _xd_error 'dosya yoneticisini acacak bir komut bulunamadi (xdg-open).'
    return 1
}

_xd_help() {
    cat <<'EOF'
Kullanim:
  xd <ad>                 Kayitli klasore git
  xd -o <ad>              Kayitli klasoru dosya yoneticisinde ac
  xd -add <ad> <yol>      Yeni bir klasor adi kaydet veya guncelle
  xd -atf <ad>            Bulunulan klasoru kaydet (add this folder)
  xd -pwd <ad>            Bulunulan klasoru kaydet
  xd -remove <ad>         Kaydi sil
  xd -list                Tum kayitlari goster
  xd -help                Yardimi goster

Ornek:
  xd -add proje ~/Workspaces/proje
  xd -atf proje
  xd proje
  xd -o proje
EOF
}

xd() {
    local command=${1:-}

    case "$command" in
        -add | --add)
            if [ $# -ne 3 ]; then
                _xd_error 'kullanim: xd -add <ad> <yol>'
                return 2
            fi
            local resolved
            if [ ! -d "$3" ] || ! resolved=$(CDPATH= cd -- "$3" 2>/dev/null && pwd); then
                _xd_error "Klasor bulunamadi: $3"
                return 1
            fi
            _xd_save "$2" "$resolved"
            ;;

        -atf | --atf | -pwd | --pwd)
            if [ $# -ne 2 ]; then
                _xd_error "kullanim: xd $command <ad>"
                return 2
            fi
            _xd_save "$2" "$PWD"
            ;;

        -remove | --remove | -rm)
            if [ $# -ne 2 ]; then
                _xd_error 'kullanim: xd -remove <ad>'
                return 2
            fi
            if ! _xd_lookup "$2" >/dev/null; then
                _xd_error "Kayit bulunamadi: $2"
                return 1
            fi
            _xd_write "$2" '' || return 1
            printf 'Silindi: %s\n' "$2"
            ;;

        -list | --list | -ls)
            local data_file
            data_file=$(_xd_data_file)
            if [ ! -s "$data_file" ]; then
                echo 'Henuz kayitli klasor yok.'
                return 0
            fi
            awk -F '\t' '
                { names[NR] = $1; paths[NR] = $2; if (length($1) > width) width = length($1) }
                END {
                    if (width < 4) width = 4
                    printf "%-" width "s  %s\n", "Name", "Path"
                    printf "%-" width "s  %s\n", "----", "----"
                    for (i = 1; i <= NR; i++) printf "%-" width "s  %s\n", names[i], paths[i]
                }
            ' "$data_file"
            ;;

        -o | --o | -open | --open)
            if [ $# -ne 2 ]; then
                _xd_error 'kullanim: xd -o <ad>'
                return 2
            fi
            local destination
            destination=$(_xd_resolve "$2") || return 1
            _xd_open "$destination" || return 1
            printf 'Aciliyor: %s\n' "$destination"
            ;;

        -help | --help | -h | '')
            _xd_help
            ;;

        -*)
            _xd_error "bilinmeyen secenek: $command"
            _xd_help >&2
            return 2
            ;;

        *)
            if [ $# -ne 1 ]; then
                _xd_error 'kullanim: xd <ad>'
                return 2
            fi
            local destination
            destination=$(_xd_resolve "$1") || return 1
            CDPATH= cd -- "$destination"
            ;;
    esac
}

# Kayitli adlar icin sekme tamamlama
_xd_names() {
    local data_file
    data_file=$(_xd_data_file)
    [ -f "$data_file" ] && awk -F '\t' '{ print $1 }' "$data_file"
}

if [ -n "${BASH_VERSION:-}" ]; then
    _xd_complete() {
        local current=${COMP_WORDS[COMP_CWORD]}
        local previous=${COMP_WORDS[COMP_CWORD-1]}
        local IFS=$'\n'
        COMPREPLY=()
        if [ "$COMP_CWORD" -eq 1 ]; then
            case "$current" in
                -*) COMPREPLY=($(compgen -W $'-add\n-atf\n-pwd\n-o\n-open\n-remove\n-list\n-help' -- "$current")) ;;
                *) COMPREPLY=($(compgen -W "$(_xd_names)" -- "$current")) ;;
            esac
        elif [ "$COMP_CWORD" -eq 2 ]; then
            case "$previous" in
                -o | -open | -remove | -rm | -atf | -pwd | -add)
                    COMPREPLY=($(compgen -W "$(_xd_names)" -- "$current")) ;;
            esac
        elif [ "$COMP_CWORD" -eq 3 ] && [ "${COMP_WORDS[1]}" = '-add' ]; then
            COMPREPLY=($(compgen -d -- "$current"))
        fi
    }
    complete -o filenames -F _xd_complete xd
elif [ -n "${ZSH_VERSION:-}" ]; then
    _xd_zsh_complete() {
        if (( CURRENT == 2 )); then
            if [[ $PREFIX == -* ]]; then
                compadd -- -add -atf -pwd -o -open -remove -list -help
            else
                compadd -- ${(f)"$(_xd_names)"}
            fi
        elif (( CURRENT == 3 )); then
            compadd -- ${(f)"$(_xd_names)"}
        elif (( CURRENT == 4 )) && [[ $words[2] == -add ]]; then
            _files -/
        fi
    }
    (( $+functions[compdef] )) && compdef _xd_zsh_complete xd
fi
