import Foundation

extension Notification.Name {
    static let AppSettingsDidChange = Notification.Name("appSettingsDidChange")
    static let languageDidChange = Notification.Name("languageDidChange")
    static let promptDidChange = Notification.Name("promptDidChange")
    static let toggleRecorderPanel = Notification.Name("toggleRecorderPanel")
    static let dismissRecorderPanel = Notification.Name("dismissRecorderPanel")
    static let didChangeModel = Notification.Name("didChangeModel")
    static let transcribeCppModelDeleted = Notification.Name("transcribeCppModelDeleted")
    static let showMainWindowRequested = Notification.Name("showMainWindowRequested")
    static let modeConfigurationApplied = Notification.Name("modeConfigurationApplied")
    static let modeConfigurationsDidChange = Notification.Name("ModeConfigurationsDidChange")
    static let modeShortcutAvailabilityDidChange = Notification.Name("modeShortcutAvailabilityDidChange")
    static let transcriptionCreated = Notification.Name("transcriptionCreated")
    static let transcriptionCompleted = Notification.Name("transcriptionCompleted")
    static let transcriptionDeleted = Notification.Name("transcriptionDeleted")
    static let wordReplacementsDidChange = Notification.Name("wordReplacementsDidChange")
    static let recordingDeviceChangeRequired = Notification.Name("recordingDeviceChangeRequired")
}
