# Diktat

Diktat ist eine schlanke, rein lokale Diktier-App für macOS 15+. Hotkey drücken, sprechen, der erkannte Text wird in die aktive App eingefügt. Die Transkription läuft vollständig auf dem Mac, es gibt keine Cloud-Anbieter und keine Konten.

Bundle-ID: `de.die-lithothek.diktat`

## Herkunft

Diktat basiert auf [VoiceInk](https://github.com/Beingpax/VoiceInk) von Beingpax und steht wie das Original unter der GPL-3.0 (siehe `LICENSE`). Die ursprünglichen Copyright-Hinweise im Quelltext bleiben erhalten. Details zum Upstream-Stand: [UPSTREAM.md](UPSTREAM.md).

## Was entfernt wurde

Cloud-Transkription, KI-Nachbearbeitung (LLM, Assistent, Screen-Kontext), Modi und App-Erkennung, Lizenzierung, Onboarding, Auto-Updates (Sparkle), Dashboard und Statistik, Audio-Import, Backup, iCloud-Sync sowie der Refine-XPC-Dienst. Geblieben sind Aufnahme, Hotkeys, Overlay, lokale Modelle, Einfügen, Verlauf und Wörterbuch (Textersetzung).

## Bauen

Voraussetzungen: macOS 15+, Xcode mit Command Line Tools, Git.

```bash
make check   # Werkzeuge prüfen
make local   # Release-Build, Ergebnis: ~/Downloads/Diktat.app
```

Alternativ baut der GitHub-Actions-Workflow „build“ (Push auf `diktat/**` oder manuell gestartet) die App auf einem macOS-Runner. Das Ergebnis liegt als Artefakt `build` (`app.zip`, `build.log`) am Workflow-Lauf. Mehr dazu in [BUILDING.md](BUILDING.md).

## Modelle

- **Parakeet TDT 0.6B v3** (Standardmodell, über FluidAudio): wird beim ersten Start automatisch geladen. FluidAudio legt die Modelle unter `~/Library/Application Support/FluidAudio/Models` ab. Die App-Daten (Verlauf, Wörterbuch, Whisper-Modelle) liegen in `~/Library/Application Support/de.die-lithothek.diktat`.
- **Canary 180M Flash** (GGUF, `canary-180m-flash-Q8_0.gguf`; Deutsch, Englisch, Spanisch, Französisch): Diktat sucht die Datei zuerst im Handy-Ordner `~/Library/Application Support/com.pais.handy/` (rekursiv) und nutzt sie direkt, ohne Kopie und ohne Prüfsumme. Wird sie dort nicht gefunden, lädt Diktat sie aus `handy-computer/canary-180m-flash-gguf` nach `~/Library/Application Support/de.die-lithothek.diktat/TranscribeCpp/canary-180m-flash/`.
- **Whisper large-v3-turbo (q5_0)**: in der Modellbibliothek als „Large v3 Turbo (Quantized)“ wählbar und ladbar (Ablage in `…/de.die-lithothek.diktat/WhisperModels`).

## Berechtigungen

- **Mikrofon**: zum Aufnehmen.
- **Bedienungshilfen**: zum Einfügen des Textes in die aktive App und für globale Hotkeys.

Beim ersten Start führt ein kleiner Dialog durch beide Berechtigungen. Bei Ad-hoc-signierten Builds fragt macOS nach jedem neuen Build erneut.

## Weitergeben (signiert und notarisiert)

Voraussetzung: Mitgliedschaft im Apple Developer Program.

Einmalig vorbereiten:

1. In Xcode unter *Einstellungen → Konten → Zertifikate verwalten → +* ein Zertifikat **Developer ID Application** anlegen.
2. Unter [appleid.apple.com](https://appleid.apple.com) ein **app-spezifisches Passwort** erzeugen.
3. Zugangsdaten für die Notarisierung im Schlüsselbund ablegen. Das Skript findet die Team-ID selbst, fragt nach deiner Apple-ID und lässt Apples Werkzeug das Passwort abfragen (es wird nirgends gespeichert außer im Schlüsselbund):

   ```bash
   make release-setup
   ```

Danach genügt:

```bash
make release
```

Das baut Diktat mit Hardened Runtime, lässt es von Apple notarisieren und legt `~/Downloads/Diktat.dmg` ab. Diese Datei öffnet sich auf anderen Macs ohne Sicherheitswarnung. Dauer: etwa 10–20 Minuten, davon einige Minuten Wartezeit bei Apple.

Mehrere Zertifikate? Dann `DEVELOPER_ID="Developer ID Application: Name (TEAMID)" make release`.
