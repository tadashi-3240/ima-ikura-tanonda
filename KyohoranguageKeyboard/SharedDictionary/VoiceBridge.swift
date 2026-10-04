import Foundation

/// Shared voice session between Keyboard Extension and host app (App Group only).
enum VoiceSessionStatus: String, Codable, Equatable {
    case idle
    case requesting
    case listening
    case ready
    case cancelled
    case error
}

struct VoicePayload: Codable, Equatable {
    var status: VoiceSessionStatus
    var sessionId: UUID
    var rawText: String
    var errorMessage: String?
    var updatedAt: Date
    /// When the keyboard (or host) started this session — used for timeouts.
    var requestedAt: Date

    enum CodingKeys: String, CodingKey {
        case status, sessionId, rawText, errorMessage, updatedAt, requestedAt
    }

    init(
        status: VoiceSessionStatus,
        sessionId: UUID,
        rawText: String,
        errorMessage: String?,
        updatedAt: Date,
        requestedAt: Date
    ) {
        self.status = status
        self.sessionId = sessionId
        self.rawText = rawText
        self.errorMessage = errorMessage
        self.updatedAt = updatedAt
        self.requestedAt = requestedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(VoiceSessionStatus.self, forKey: .status)
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText) ?? ""
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        requestedAt = try container.decodeIfPresent(Date.self, forKey: .requestedAt) ?? updatedAt
    }

    static func idle() -> VoicePayload {
        let now = Date()
        return VoicePayload(
            status: .idle,
            sessionId: UUID(),
            rawText: "",
            errorMessage: nil,
            updatedAt: now,
            requestedAt: now
        )
    }

    var age: TimeInterval {
        Date().timeIntervalSince(requestedAt)
    }
}

enum VoiceBridge {
    /// Give up waiting for host open / completion after this many seconds.
    static let sessionTimeout: TimeInterval = 45

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

    @discardableResult
    static func beginRequest() -> VoicePayload {
        let now = Date()
        let payload = VoicePayload(
            status: .requesting,
            sessionId: UUID(),
            rawText: "",
            errorMessage: nil,
            updatedAt: now,
            requestedAt: now
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

    /// True when a session has been waiting too long without a ready result.
    static func isTimedOut(_ payload: VoicePayload) -> Bool {
        switch payload.status {
        case .requesting, .listening:
            return payload.age >= sessionTimeout
        default:
            return false
        }
    }
}
