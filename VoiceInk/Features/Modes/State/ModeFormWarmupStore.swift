import Combine
import Foundation

struct ModeFormWarmupSnapshot {
    let usableTranscriptionModels: [any TranscriptionModel]
    let allTranscriptionModels: [any TranscriptionModel]

    static let empty = ModeFormWarmupSnapshot(
        usableTranscriptionModels: [],
        allTranscriptionModels: []
    )

    @MainActor
    init(transcriptionModelManager: TranscriptionModelManager) {
        usableTranscriptionModels = transcriptionModelManager.usableModels
        allTranscriptionModels = transcriptionModelManager.allAvailableModels
    }

    private init(
        usableTranscriptionModels: [any TranscriptionModel],
        allTranscriptionModels: [any TranscriptionModel]
    ) {
        self.usableTranscriptionModels = usableTranscriptionModels
        self.allTranscriptionModels = allTranscriptionModels
    }

    func transcriptionModel(named name: String?) -> (any TranscriptionModel)? {
        guard let name else { return nil }
        return TranscriptionModelRegistry.model(forSelectionKey: name, in: allTranscriptionModels)
    }

    func hasUsableTranscriptionModel(named name: String) -> Bool {
        transcriptionModel(named: name).map { model in
            usableTranscriptionModels.contains { $0.selectionKey == model.selectionKey }
        } ?? false
    }
}

@MainActor
final class ModeFormWarmupStore: ObservableObject {
    static let shared = ModeFormWarmupStore()

    @Published private(set) var snapshot = ModeFormWarmupSnapshot.empty
    @Published private(set) var installedApps: [InstalledAppInfo] = []
    @Published private(set) var isLoadingInstalledApps = false

    private weak var transcriptionModelManager: TranscriptionModelManager?

    private var cancellables = Set<AnyCancellable>()
    private var notificationObservers: [NSObjectProtocol] = []
    private var pendingSnapshotRefresh: DispatchWorkItem?
    private var hasSnapshot = false

    private init() {}

    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        pendingSnapshotRefresh?.cancel()
    }

    func configure(transcriptionModelManager: TranscriptionModelManager) {
        let dependenciesChanged = self.transcriptionModelManager !== transcriptionModelManager

        self.transcriptionModelManager = transcriptionModelManager

        if dependenciesChanged {
            installChangeObservers()
        }

        if dependenciesChanged || !hasSnapshot {
            refreshSnapshot()
        }
        loadInstalledAppsIfNeeded()
    }

    func refreshSnapshot() {
        guard let transcriptionModelManager else { return }

        snapshot = ModeFormWarmupSnapshot(transcriptionModelManager: transcriptionModelManager)
        hasSnapshot = true
    }

    func scheduleSnapshotRefresh() {
        pendingSnapshotRefresh?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.refreshSnapshot()
            }
        }

        pendingSnapshotRefresh = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    func loadInstalledAppsIfNeeded() {
        guard installedApps.isEmpty else { return }
        refreshInstalledApps()
    }

    func refreshInstalledApps() {
        guard !isLoadingInstalledApps else { return }

        isLoadingInstalledApps = true

        DispatchQueue.global(qos: .utility).async {
            let apps = InstalledApps.load()

            Task { @MainActor in
                self.installedApps = apps
                self.isLoadingInstalledApps = false
            }
        }
    }

    private func installChangeObservers() {
        cancellables.removeAll()
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()

        transcriptionModelManager?.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleSnapshotRefresh()
                }
            }
            .store(in: &cancellables)

        let notificationNames: [Notification.Name] = [
            .AppSettingsDidChange
        ]

        notificationObservers = notificationNames.map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleSnapshotRefresh()
                }
            }
        }
    }
}
