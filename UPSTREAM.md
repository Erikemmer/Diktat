# Upstream

Diktat ist ein Fork von [Beingpax/VoiceInk](https://github.com/Beingpax/VoiceInk).

- Upstream-Stand: Commit `d791c15` (Beingpax/VoiceInk, Branch `main`)
- Lizenz: GPL-3.0, unverändert

## Entfernte Ordner und Dateien (gegenüber d791c15)

- `VoiceInk/Features/`: `Assistant`, `AudioImport`, `Dashboard`, `Enhancement`, `Licensing`, `Modes`, `Onboarding`
- `VoiceInk/Core/Enhancement`
- `VoiceInk/Infrastructure/`: `Credentials`, `ExternalServices`, `Licensing`, `RemoteConfig`
- `VoiceInk/Infrastructure/Providers/Enhancement`, `VoiceInk/Infrastructure/Providers/Transcription/Cloud`
- `VoiceInk/Infrastructure/SystemIntegration/` (Context, ScreenCapture)
- `VoiceInk/Features/Dictionary/` (AutoLearn)
- `VoiceInk/App/`: `Updates`, `ChangeLog`
- `VoiceInkRefineXPC`, `Shared`
- `appcast.xml`, `announcements.json`, `release/`, `release-notes/`, `scripts/` (Release-Skripte)
- Asset-Kataloge für Cloud-Anbieter-Logos

Genaue Liste: `git diff --diff-filter=D --name-only d791c15 HEAD`

## Upstream-Änderungen übernehmen

```bash
git fetch upstream
git log --oneline d791c15..upstream/main   # was ist neu?
git cherry-pick <commit>                   # einzelne Änderungen übernehmen
```

Cherry-Picks können an entfernten Dateien oder an den umbenannten Pfaden (Bundle-ID `de.die-lithothek.diktat`, Application-Support-Ordner) in Konflikte laufen. Swift-Modulname und Target heißen weiterhin `VoiceInk`, damit Upstream-Patches sauber passen.
