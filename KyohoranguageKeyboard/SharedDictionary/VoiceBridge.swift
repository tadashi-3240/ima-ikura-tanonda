import Foundation

/// Shared voice session between Keyboard Extension and host app (App Group only).
enum VoiceSessionStatus: String, Codable, Equatable {
    /// Nothing pending.
    case idle
    /// Keyboard asked the host to start listening.
    case requesting
    /// Host is recording / recognizing.
    case listening
    /// Final text is ready for the keyboard to insert.
    case ready
    case cancelled
    case error
}

struct VoicePayload: Codable, Equatable {
    var status: VoiceSessionStatus
    var sessionId: UUID
    /// Raw speech recognition text (before dictionary correction).
    var rawText: String
    var errorMessage: String?
    var updatedAt: Date

    static func idle() -> VoicePayload {
        VoicePayload(
            status: .idle,
            sessionId: UUID(),
            rawText: "",
            errorMessage: nil,
            updatedAt: Date()
        )
    }
}

enum VoiceBridge {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func load() -> VoicePayload {
        guard let defaults = AppGroupConstants.sharedDefaults,
              let data = defaults.data(forKey: AppGroupConstants.voicePayloadKey),
              let payload = try? decoder.decode(VoicePayload.self, from: data) else {
            return .idle()
        }
        return payload
    }

    @discardableResult
    static func save(_ payload: VoicePayload) -> Bool {
        guard let defaults = AppGroupConstants.sharedDefaults,
              let data = try? encoder.encode(payload) else { return false }
        defaults.set(data, forKey: AppGroupConstants.voicePayloadKey)
        defaults.synchronize()
        return true
    }

    /// Keyboard starts a new voice request before opening the host.
    @discardableResult
    static func beginRequest() -> VoicePayload {
        let payload = VoicePayload(
            status: .requesting,
            sessionId: UUID(),
            rawText: "",
            errorMessage: nil,
            updatedAt: Date()
        )
        _ = save(payload)
        return payload
    }

    static func markListening(sessionId: UUID) {
        var payload = load()
        guard payload.sessionId == sessionId || payload.status == .requesting else { return }
        payload.status = .listening
        payload.sessionId = sessionId
        payload.updatedAt = Date()
        _ = save(payload)
    }

    static func markReady(sessionId: UUID, rawText: String) {
        var payload = load()
        payload.status = .ready
        payload.sessionId = sessionId
        payload.rawText = rawText
        payload.errorMessage = nil
        payload.updatedAt = Date()
        _ = save(payload)
    }

    static func markError(sessionId: UUID, message: String) {
        var payload = load()
        payload.status = .error
        payload.sessionId = sessionId
        payload.errorMessage = message
        payload.updatedAt = Date()
        _ = save(payload)
    }

    static func markCancelled(sessionId: UUID) {
        var payload = load()
        payload.status = .cancelled
        payload.sessionId = sessionId
        payload.updatedAt = Date()
        _ = save(payload)
    }

    static func clear() {
        _ = save(.idle())
    }
}
