# Analyse VoiceInk für „Diktat“ (Schritt 1, nur gelesen, nichts gebaut)

Swift gesamt ca. 72.400 Zeilen. Größte Features-Ordner: ModelLibrary 8,3k, Dictionary 7,7k, Modes 6,1k, Onboarding 5,3k, Recording 4,8k, Dashboard 4,5k, History 3,9k, Shortcuts 3,2k, Enhancement 2,3k, Licensing 1,9k.

## Kern-Pipeline (Pfade unter VoiceInk/)
- Hotkey: Features/Shortcuts (ShortcutMonitor = CGEventTap, RecordingShortcutManager mit toggle/pushToTalk/hybrid)
- Aufnahme: Features/Recording/Capture/Recorder*.swift, Infrastructure/Audio/CoreAudioRecorder.swift, Audio/Devices
- Overlay: Recording/Presentation (MiniRecorderPanel, MiniWindowManager), Recording/Views/MiniRecorderView
- Orchestrierung: Recording/Workflows/VoiceInkEngine.swift, TranscriptionPipeline, TranscriptionServiceRegistry, TranscriptionDelivery
- Transkription: Infrastructure/Providers/Transcription/{FluidAudio,TranscribeCpp,Whisper}
- Einfügen: Infrastructure/SystemIntegration/Paste (CursorPaster, ClipboardManager)

## Entfernen (Ordner)
Features/{Enhancement,Assistant,Modes*,Licensing,Onboarding,Dashboard,AudioImport}, Core/Enhancement, Infrastructure/{Licensing,RemoteConfig,Credentials,ExternalServices}, Providers/Enhancement, Providers/Transcription/Cloud, SystemIntegration/{Context,ScreenCapture}, App/{Updates,ChangeLog}, Dictionary/AutoLearn, VoiceInkRefineXPC/, Shared/, appcast.xml, announcements.json, release/, release-notes/, scripts/release*.
(*aus Modes nur ModeRuntimeResolver durch direkten Zugriff auf Modell/Sprache ersetzen.)

## Kopplungsstellen (minimal anpassen)
App/VoiceInk.swift, VoiceInkEngine(+Assistant), TranscriptionPipeline (Enhancement-Block), TranscriptionDelivery, TranscriptionServiceRegistry, TranscriptionModelManager, ModelProvider-Enum, ShortcutAction (.mode, .pasteLastEnhancement …), ContentView, MenuBarView, SettingsView, AppDefaults, History-Views (Enhancement-Felder).

## Wegfallende Abhängigkeiten
SPM: Sparkle, LLMkit, mlx-swift-lm, swift-huggingface, swift-transformers, swift-markdown-ui, EventSource, SelectedTextKit, ggf. mediaremote-adapter. Target VoiceInkRefineXPC + Embed-Phase. Info.plist-SU*-Keys. Release-Entitlements: iCloud, aps, keychain-groups, mach-lookup.
Bleiben: FluidAudio, Transcribe-cpp-swift, swift-atomics, vorerst whisper.xcframework.

## Modelle
- Registry: Features/ModelLibrary/Models/TranscriptionModelRegistry.swift (predefinedModels)
- GGUF: TranscribeCppModelCatalog.swift (Artifact mit Datei, Repo, Größe, SHA256, architectureHint). Pfad: ~/Library/Application Support/<BundleID>/TranscribeCpp/<Modell>/<Datei>. Für Canary: neues Artifact + Eintrag; sauberste Lösung ist optionaler localFileURL (Handy-Datei direkt). Größe/SHA256 müssen auf dem Mac ermittelt werden.
- Parakeet v3 als Default: kein Mechanismus vorhanden; Fallback in loadCurrentTranscriptionModel + Auto-Download beim Erststart.
- Whisper zunächst behalten (Entfernen aufwändiger).

## Wörterbuch / Verlauf
Textersetzung (WordReplacementService) ist LLM-frei, bleibt. Vokabular fließt ohne Enhancement derzeit nirgends in die Transkription. SwiftData-`Transcription` hat Enhancement-Felder: vorerst stehen lassen, nicht befüllen (keine Migration).

## Build
make check prüft git/xcodebuild/swift. make local baut whisper.xcframework nach ~/VoiceInk-Dependencies, Release-Build, signiert, legt VoiceInk.app in ~/Downloads. Umbenennung betrifft Bundle-ID (com.prakashjoshipax.VoiceInk*), App-Name, Makefile, App-Support-Pfad.

## Commit-Reihenfolge
1 Sparkle/Release-Artefakte · 2 RefineXPC · 3 Lizenz · 4 Onboarding/Announcements · 5 Cloud-Transkription · 6 LLM/Enhancement/Assistant/Screen-Context · 7 Modes/App-Erkennung (riskantester) · 8 Dashboard/AudioImport/iCloud · 9 Canary-Eintrag, Parakeet-Default, Umbenennung · 10 optional Whisper etc.
