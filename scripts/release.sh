#!/bin/bash
# Baut Diktat mit "Developer ID Application", lässt die App von Apple notarisieren
# und erzeugt eine installierbare Diktat.dmg in ~/Downloads.
#
# Einmalig vorbereiten (siehe README.md, Abschnitt "Weitergeben"):
#   1. Zertifikat "Developer ID Application" in Xcode anlegen
#   2. xcrun notarytool store-credentials "diktat-notary" ...
#
# Aufruf: make release        (oder: ./scripts/release.sh)
# Optional: DEVELOPER_ID="Developer ID Application: Name (TEAMID)" NOTARY_PROFILE=name ./scripts/release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NOTARY_PROFILE="${NOTARY_PROFILE:-diktat-notary}"
BUILD_DIR="$ROOT/.release-build"
APP_NAME="Diktat"
OUT_DIR="$HOME/Downloads"

# --- Identität bestimmen -----------------------------------------------------
if [ -z "${DEVELOPER_ID:-}" ]; then
	IDENTITIES=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application:/ { print $2 }')
	COUNT=$(printf '%s\n' "$IDENTITIES" | awk 'NF { c++ } END { print c + 0 }')
	if [ "$COUNT" -eq 0 ]; then
		echo "Fehler: Kein 'Developer ID Application'-Zertifikat im Schlüsselbund gefunden." >&2
		echo "Xcode > Einstellungen > Konten > Zertifikate verwalten > + > Developer ID Application" >&2
		exit 1
	elif [ "$COUNT" -gt 1 ]; then
		echo "Mehrere Zertifikate gefunden, bitte DEVELOPER_ID setzen:" >&2
		printf '%s\n' "$IDENTITIES" >&2
		exit 1
	fi
	DEVELOPER_ID="$IDENTITIES"
fi
echo "Signiere mit: $DEVELOPER_ID"

# --- Notarisierungs-Zugang prüfen -------------------------------------------
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
	echo "Fehler: Notary-Profil '$NOTARY_PROFILE' fehlt oder ist ungültig." >&2
	echo "Einmalig anlegen: xcrun notarytool store-credentials \"$NOTARY_PROFILE\" --apple-id <ID> --team-id <TEAMID>" >&2
	exit 1
fi

# --- Whisper-Framework sicherstellen ----------------------------------------
make whisper

# --- Bauen -------------------------------------------------------------------
rm -rf "$BUILD_DIR"
xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Release \
	-derivedDataPath "$BUILD_DIR" \
	-xcconfig LocalBuild.xcconfig \
	CODE_SIGN_IDENTITY="$DEVELOPER_ID" \
	CODE_SIGNING_REQUIRED=YES \
	CODE_SIGNING_ALLOWED=YES \
	DEVELOPMENT_TEAM="" \
	OTHER_CODE_SIGN_FLAGS="--timestamp" \
	ENABLE_HARDENED_RUNTIME=YES \
	CODE_SIGN_ENTITLEMENTS="$ROOT/VoiceInk/VoiceInk.local.entitlements" \
	SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) LOCAL_BUILD' \
	-skipPackagePluginValidation -skipMacroValidation \
	build

APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
[ -d "$APP" ] || { echo "Fehler: $APP nicht gefunden" >&2; exit 1; }

echo "Prüfe Signatur..."
codesign --verify --deep --strict --verbose=2 "$APP"

# --- App notarisieren ----------------------------------------------------------
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ditto -c -k --keepParent "$APP" "$WORK/$APP_NAME.zip"
echo "Sende App an Apple zur Notarisierung (dauert meist 1-10 Minuten)..."
xcrun notarytool submit "$WORK/$APP_NAME.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

# --- DMG bauen, signieren, notarisieren -----------------------------------
mkdir -p "$WORK/dmg"
ditto "$APP" "$WORK/dmg/$APP_NAME.app"
ln -s /Applications "$WORK/dmg/Applications"
DMG="$OUT_DIR/$APP_NAME.dmg"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$WORK/dmg" -ov -format UDZO "$DMG"
codesign --force --sign "$DEVELOPER_ID" --timestamp "$DMG"
echo "Sende DMG an Apple..."
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo ""
echo "Fertig: $DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG" || true
