#!/bin/bash
#
# ci_post_clone.sh — Xcode Cloud, depo klonlandıktan hemen sonra bu betiği çalıştırır.
#
# NEDEN VAR (CLAUDE.md K-07, 5.6 kural 3):
# Gizli değerler depoya girmez. Xcode Cloud'da ortam değişkeni olarak tanımlanır ve
# derlemeden önce bu betik tarafından yerine yazılır:
#   MAPBOX_DOWNLOAD_TOKEN  → ~/.netrc          (Mapbox SDK ikililerinin indirilmesi)
#   MAPBOX_PUBLIC_TOKEN    → Config/Secrets.xcconfig  (uygulamaya gömülen genel token)
#
# Değişkenlerden biri eksikse betik açık bir mesajla durur. Sessizce devam etmek,
# derlemenin paket çözümlemesinde ya da token'sız açılan bir haritada anlaşılmaz
# biçimde kırılmasına yol açardı.
#
# Xcode Cloud betiği `ci_scripts/` klasöründen çalıştırır; klasör depo kökünde olmak
# ZORUNDADIR.

set -euo pipefail

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SECRETS_FILE="$REPO_ROOT/Config/Secrets.xcconfig"
NETRC_FILE="$HOME/.netrc"

fail() {
    printf 'ci_post_clone.sh: HATA: %s\n' "$1" >&2
    exit 1
}

if [[ -z "${MAPBOX_DOWNLOAD_TOKEN:-}" ]]; then
    fail "MAPBOX_DOWNLOAD_TOKEN tanımlı değil. Xcode Cloud → iş akışı → Environment → Secret olarak ekleyin."
fi

if [[ -z "${MAPBOX_PUBLIC_TOKEN:-}" ]]; then
    fail "MAPBOX_PUBLIC_TOKEN tanımlı değil. Xcode Cloud → iş akışı → Environment → Secret olarak ekleyin."
fi

# İki token yer değiştirirse hata sessizce geçer: gizli (`sk.`) token uygulama paketine
# gömülüp herkesçe okunabilir hale gelir, genel (`pk.`) token ise indirmede yetkisiz kalır.
if [[ "$MAPBOX_DOWNLOAD_TOKEN" != sk.* ]]; then
    fail "MAPBOX_DOWNLOAD_TOKEN 'sk.' ile başlamıyor. İndirme için GİZLİ token (DOWNLOADS:READ) gerekir."
fi

if [[ "$MAPBOX_PUBLIC_TOKEN" != pk.* ]]; then
    fail "MAPBOX_PUBLIC_TOKEN 'pk.' ile başlamıyor. Uygulamaya yalnızca GENEL token gömülür."
fi

# Dosyalar oluşturulduğu andan itibaren yalnızca sahibine okunur olsun.
umask 077

printf 'machine api.mapbox.com\nlogin mapbox\npassword %s\n' "$MAPBOX_DOWNLOAD_TOKEN" > "$NETRC_FILE"
chmod 600 "$NETRC_FILE"

printf '// Xcode Cloud tarafından ci_scripts/ci_post_clone.sh ile üretildi. Elle düzenlemeyin.\nMAPBOX_PUBLIC_TOKEN = %s\n' \
    "$MAPBOX_PUBLIC_TOKEN" > "$SECRETS_FILE"

printf 'ci_post_clone.sh: ~/.netrc ve Config/Secrets.xcconfig oluşturuldu.\n'
