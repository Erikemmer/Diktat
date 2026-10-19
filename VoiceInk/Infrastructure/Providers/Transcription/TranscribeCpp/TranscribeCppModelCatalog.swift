import Foundation

struct TranscribeCppModelArtifact: Sendable {
    let modelName: String
    let fileName: String
    let repository: String
    let repositoryRevision: String
    let expectedFileSize: Int64
    let expectedSHA256: String?
    let architectureHint: String?
    let enablesInverseTextNormalization: Bool
    let maximumChunkSeconds: Int
    let boundarySearchSeconds: Int
    let boundaryEnergyWindowSamples: Int
    /// When true, an existing file with this name in the Handy app folder is used directly (no size/checksum check, no copy).
    var searchesHandyModelFolder: Bool = false

    var downloadURL: URL {
        URL(
            string: "https://huggingface.co/\(repository)/resolve/\(repositoryRevision)/\(fileName)"
        )!
    }

    var modelDirectory: URL {
        Self.applicationSupportDirectory
            .appendingPathComponent("TranscribeCpp", isDirectory: true)
            .appendingPathComponent(modelName, isDirectory: true)
    }

    var modelFileURL: URL {
        modelDirectory.appendingPathComponent(fileName, isDirectory: false)
    }

    var checksumFileURL: URL {
        modelDirectory.appendingPathComponent(".\(fileName).sha256", isDirectory: false)
    }

    var installedModelFileURL: URL? {
        if searchesHandyModelFolder, let handyFileURL = Self.handyModelFileURL(named: fileName) {
            return handyFileURL
        }
        return modelFileIsValid(in: modelDirectory) ? modelFileURL : nil
    }

    func modelFileIsValid(in directory: URL) -> Bool {
        let fileURL = directory.appendingPathComponent(fileName, isDirectory: false)
        let checksumURL = directory.appendingPathComponent(".\(fileName).sha256", isDirectory: false)

        guard
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
            values.isRegularFile == true,
            let size = values.fileSize,
            Int64(size) == expectedFileSize
        else {
            return false
        }

        guard let expectedSHA256 else { return true }
        let installedChecksum = try? String(contentsOf: checksumURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return installedChecksum == expectedSHA256
    }

    func removeInstalledFiles() {
        try? FileManager.default.removeItem(at: modelDirectory)
    }

    private static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("de.die-lithothek.diktat", isDirectory: true)
    }

    private static var handyApplicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("com.pais.handy", isDirectory: true)
    }

    private final class HandyLookupCache: @unchecked Sendable {
        let lock = NSLock()
        var entries: [String: (url: URL?, checkedAt: Date)] = [:]
    }

    private static let handyLookupCache = HandyLookupCache()

    /// Recursively looks for `name` below the Handy app folder. Results are cached briefly because this is queried from UI code.
    private static func handyModelFileURL(named name: String) -> URL? {
        handyLookupCache.lock.lock()
        defer { handyLookupCache.lock.unlock() }

        if let cached = handyLookupCache.entries[name] {
            if let url = cached.url {
                if FileManager.default.fileExists(atPath: url.path) { return url }
            } else if Date().timeIntervalSince(cached.checkedAt) < 5 {
                return nil
            }
        }

        var found: URL?
        if let enumerator = FileManager.default.enumerator(
            at: handyApplicationSupportDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator where url.lastPathComponent == name {
                if (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
                    found = url
                    break
                }
            }
        }
        handyLookupCache.entries[name] = (found, Date())
        return found
    }
}

enum TranscribeCppModelCatalog {
    static let cohereTranscribe = TranscribeCppModelArtifact(
        modelName: "cohere-transcribe",
        fileName: "cohere-transcribe-03-2026-Q4_K_M.gguf",
        repository: "handy-computer/cohere-transcribe-03-2026-gguf",
        repositoryRevision: "dfa4adebb64f3076b7b6b90b721275cc069cb421",
        expectedFileSize: 1_558_162_944,
        expectedSHA256: "0ea56826d8bd5d74b7143a4a04e022dc1bb75452cfae49d98b6acb0c1d16a1fb",
        architectureHint: "cohere",
        enablesInverseTextNormalization: false,
        maximumChunkSeconds: 35,
        boundarySearchSeconds: 5,
        boundaryEnergyWindowSamples: 1_600
    )

    static let senseVoiceSmall = TranscribeCppModelArtifact(
        modelName: "sensevoice-small",
        fileName: "SenseVoiceSmall-Q8_0.gguf",
        repository: "handy-computer/SenseVoiceSmall-gguf",
        repositoryRevision: "4a08b8e900b38a977e32eb08d5d0697d6e72ba04",
        expectedFileSize: 252_684_608,
        expectedSHA256: "6c759ee4c9748c9b3f7a5a60ca74f0f7e685fb9d45d1378fce7cfd62f59adf29",
        architectureHint: "sensevoice",
        enablesInverseTextNormalization: true,
        maximumChunkSeconds: 30,
        boundarySearchSeconds: 3,
        boundaryEnergyWindowSamples: 1_600
    )

    // Size 218,447,648 bytes is taken from the transcribe.cpp catalog (canary-180m-flash.json). The SHA256 is unknown,
    // so none is verified. The architecture name "canary" is the arch identifier in transcribe.cpp (src/arch/canary).
    static let canary180mFlash = TranscribeCppModelArtifact(
        modelName: "canary-180m-flash",
        fileName: "canary-180m-flash-Q8_0.gguf",
        repository: "handy-computer/canary-180m-flash-gguf",
        repositoryRevision: "main",
        expectedFileSize: 218_447_648,
        expectedSHA256: nil,
        architectureHint: "canary",
        enablesInverseTextNormalization: false,
        maximumChunkSeconds: 35,
        boundarySearchSeconds: 5,
        boundaryEnergyWindowSamples: 1_600,
        searchesHandyModelFolder: true
    )

    private static let artifactsByModelName = [
        cohereTranscribe.modelName: cohereTranscribe,
        senseVoiceSmall.modelName: senseVoiceSmall,
        canary180mFlash.modelName: canary180mFlash,
    ]

    static func artifact(for modelName: String) -> TranscribeCppModelArtifact? {
        artifactsByModelName[modelName]
    }
}
