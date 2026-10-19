import Foundation

extension Transcription {
    var preferredHistoryText: String {
        text
    }

    var availableHistoryAudioURL: URL? {
        guard let audioFileURL,
            let url = URL(string: audioFileURL),
            FileManager.default.fileExists(atPath: url.path)
        else {
            return nil
        }
        return url
    }
}
