#!/bin/bash
#
# verify-ios.sh — Projeyi iOS hedefi için derleyip doğrular.
#
# NEDEN VAR (CLAUDE.md K-18):
# `swift build` ana makine (macOS) için derler. Package.swift içindeki .iOS(.v17)
# bildirimi orada sınanmaz. UIKit, CarPlay, ActivityKit veya Mapbox kullanan bir modül
# `swift build` ile yeşil görünüp iOS'ta derlenmeyebilir.
# Bu betik gerçek iOS hedefiyle derleyerek o boşluğu kapatır.
#
# KULLANIM:
#   ./Tooling/Scripts/verify-ios.sh            # her şeyi doğrula
#   ./Tooling/Scripts/verify-ios.sh --app      # yalnızca uygulama şeması (hızlı)
#
# Yavaştır. Her kaydetmede değil, inceleme isteği göndermeden önce çalıştırın.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

DESTINATION='generic/platform=iOS Simulator'
PACKAGES=(Domain Core MapboxKit Services Features)
APP_ONLY=false
FAILED=()

[[ "${1:-}" == "--app" ]] && APP_ONLY=true

say() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; }

# ─── 1. Uygulama şeması ───
# Uygulama hedefine bağlı tüm paket ürünlerini de derler.
say "Uygulama şeması derleniyor (Onsarj)"
if xcodebuild build \
    -project Onsarj.xcodeproj \
    -scheme Onsarj \
    -destination "$DESTINATION" \
    -quiet; then
    ok "Onsarj"
else
    bad "Onsarj"
    FAILED+=("Onsarj uygulama şeması")
fi

# ─── 2. Paketler ───
# Henüz uygulama hedefine bağlanmamış modüller buradan doğrulanır.
if [[ "$APP_ONLY" == false ]]; then
    for pkg in "${PACKAGES[@]}"; do
        say "Paket derleniyor: $pkg"
        pushd "Packages/$pkg" > /dev/null

        # Paketin şemalarını keşfet. Şema adları paketten pakete değişebildiği için
        # sabit yazmak yerine xcodebuild'e sorulur.
        schemes=$(xcodebuild -list -json 2>/dev/null \
            | python3 -c 'import sys, json; d = json.load(sys.stdin); print("\n".join((d.get("workspace") or d.get("project") or {}).get("schemes", [])))' \
            || true)

        if [[ -z "$schemes" ]]; then
            bad "$pkg — şema bulunamadı"
            FAILED+=("$pkg (şema yok)")
            popd > /dev/null
            continue
        fi

        while IFS= read -r scheme; do
            [[ -z "$scheme" ]] && continue
            if xcodebuild build -scheme "$scheme" -destination "$DESTINATION" -quiet; then
                ok "$pkg / $scheme"
            else
                bad "$pkg / $scheme"
                FAILED+=("$pkg / $scheme")
            fi
        done <<< "$schemes"

        popd > /dev/null
    done
fi

# ─── Sonuç ───
if [[ ${#FAILED[@]} -eq 0 ]]; then
    say "Tüm doğrulamalar geçti."
    exit 0
else
    say "Başarısız olanlar:"
    printf '  - %s\n' "${FAILED[@]}"
    exit 1
fi
