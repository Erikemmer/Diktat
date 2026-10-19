#!/bin/bash
# Einmalige Einrichtung für `make release`: legt die Notarisierungs-Zugangsdaten
# im Schlüsselbund ab. Das Passwort fragt Apples notarytool selbst ab; es wird
# weder angezeigt noch in einer Datei gespeichert.
set -euo pipefail

NOTARY_PROFILE="${NOTARY_PROFILE:-diktat-notary}"

IDENTITIES=$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application:/ { print $2 }')
COUNT=$(printf '%s\n' "$IDENTITIES" | awk 'NF { c++ } END { print c + 0 }')
if [ "$COUNT" -eq 0 ]; then
	echo "Noch kein 'Developer ID Application'-Zertifikat gefunden." >&2
	echo "Xcode > Einstellungen > Konten > Apple-ID wählen > Zertifikate verwalten > + > Developer ID Application" >&2
	exit 1
fi
IDENTITY=$(printf '%s\n' "$IDENTITIES" | head -1)
TEAM_ID=$(printf '%s' "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')
echo "Zertifikat: $IDENTITY"
echo "Team-ID:    $TEAM_ID"
echo ""
read -r -p "Deine Apple-ID (E-Mail): " APPLE_ID
echo ""
echo "Jetzt fragt Apple nach dem app-spezifischen Passwort (appleid.apple.com > Anmeldung und Sicherheit)."
xcrun notarytool store-credentials "$NOTARY_PROFILE" --apple-id "$APPLE_ID" --team-id "$TEAM_ID"
echo ""
echo "Fertig. Jetzt: make release"
