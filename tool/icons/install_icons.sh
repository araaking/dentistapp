#!/bin/sh
# Menyalin ikon hasil `flutter test tool/icons/render_icons_test.dart` ke
# folder Android, iOS, dan web (butuh `sips`, bawaan macOS).
set -eu
cd "$(dirname "$0")/../.."

OUT=tool/icons/out
SQUARE="$OUT/icon_square_1024.png"
ROUNDED="$OUT/icon_rounded_512.png"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# iOS menolak ikon dengan kanal alfa: buang lewat konversi ke JPEG lalu PNG.
sips -s format jpeg -s formatOptions best "$SQUARE" --out "$TMP/square.jpg" >/dev/null
sips -s format png "$TMP/square.jpg" --out "$TMP/square.png" >/dev/null

resize() { # resize <sumber> <ukuran> <tujuan>
  sips -z "$2" "$2" "$1" --out "$3" >/dev/null
}

# Android (ikon lama untuk API < 26; API 26+ memakai ikon adaptif vektor).
RES=android/app/src/main/res
resize "$ROUNDED" 48 "$RES/mipmap-mdpi/ic_launcher.png"
resize "$ROUNDED" 72 "$RES/mipmap-hdpi/ic_launcher.png"
resize "$ROUNDED" 96 "$RES/mipmap-xhdpi/ic_launcher.png"
resize "$ROUNDED" 144 "$RES/mipmap-xxhdpi/ic_launcher.png"
resize "$ROUNDED" 192 "$RES/mipmap-xxxhdpi/ic_launcher.png"

# iOS
SET=ios/Runner/Assets.xcassets/AppIcon.appiconset
for entry in 20x20@1x:20 20x20@2x:40 20x20@3x:60 29x29@1x:29 29x29@2x:58 \
  29x29@3x:87 40x40@1x:40 40x40@2x:80 40x40@3x:120 60x60@2x:120 60x60@3x:180 \
  76x76@1x:76 76x76@2x:152 83.5x83.5@2x:167 1024x1024@1x:1024; do
  resize "$TMP/square.png" "${entry##*:}" "$SET/Icon-App-${entry%%:*}.png"
done

# Web
resize "$TMP/square.png" 192 web/icons/Icon-192.png
resize "$TMP/square.png" 512 web/icons/Icon-512.png
resize "$TMP/square.png" 192 web/icons/Icon-maskable-192.png
resize "$TMP/square.png" 512 web/icons/Icon-maskable-512.png
resize "$TMP/square.png" 32 web/favicon.png

echo "Ikon terpasang."
