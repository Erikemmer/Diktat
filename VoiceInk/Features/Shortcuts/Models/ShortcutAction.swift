import Foundation

enum ShortcutAction: Hashable {
    case primaryRecording
    case secondaryRecording
    case pasteLastTranscription
    case retryLastTranscription
    case cancelRecorder
    case openQuickHistory
    case quickAddToDictionary
    case recorderPanelEscape
    case recorderPanelReturn

    var userDefaultsKey: String {
        "Shortcut_\(storageName)"
    }

    var isStored: Bool {
        switch self {
        case .recorderPanelEscape, .recorderPanelReturn:
            return false
        default:
            return true
        }
    }

    var storageName: String {
        switch self {
        case .primaryRecording:
            return "primaryRecording"
        case .secondaryRecording:
            return "secondaryRecording"
        case .pasteLastTranscription:
            return "pasteLastTranscription"
        case .retryLastTranscription:
            return "retryLastTranscription"
        case .cancelRecorder:
            return "cancelRecorder"
        case .openQuickHistory:
            return "openHistoryWindow"
        case .quickAddToDictionary:
            return "quickAddToDictionary"
        case .recorderPanelEscape:
            return "recorderPanelEscape"
        case .recorderPanelReturn:
            return "recorderPanelReturn"
        }
    }

    var displayName: String {
        switch self {
        case .primaryRecording:
            return String(localized: "Primary Shortcut")
        case .secondaryRecording:
            return String(localized: "Secondary Shortcut")
        case .pasteLastTranscription:
            return String(localized: "Paste Last Transcription")
        case .retryLastTranscription:
            return String(localized: "Retry Last Transcription")
        case .cancelRecorder:
            return String(localized: "Cancel Recording")
        case .openQuickHistory:
            return String(localized: "Open Quick History")
        case .quickAddToDictionary:
            return String(localized: "Quick Add to Dictionary")
        case .recorderPanelEscape:
            return String(localized: "Recorder Cancel")
        case .recorderPanelReturn:
            return String(localized: "Auto Send")
        }
    }

    static let globalUtilityActions: [Self] = [
        .pasteLastTranscription,
        .retryLastTranscription,
        .openQuickHistory,
        .quickAddToDictionary,
    ]

    static let recorderPanelStoredActions: [Self] = [
        .cancelRecorder
    ]

    static let legacyKeyboardShortcutActions: [Self] = [
        .primaryRecording,
        .secondaryRecording,
        .pasteLastTranscription,
        .retryLastTranscription,
        .cancelRecorder,
        .openQuickHistory,
        .quickAddToDictionary,
    ]
}
