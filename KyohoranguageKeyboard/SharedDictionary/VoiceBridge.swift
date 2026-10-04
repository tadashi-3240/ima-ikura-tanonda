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
    /// Pre-corrected text from host (keyboard may re-apply based on current toggle).
    var correctedText: String
    var errorMessage: String?
    var updatedAt: Date
    var requestedAt: Date

    enum CodingKeys: String, CodingKey {
        case status, sessionId, rawText, correctedText, errorMessage, updatedAt, requestedAt
    }

    init(
        status: VoiceSessionStatus,
        sessionId: UUID,
        rawText: String,
        correctedText: String = "",
        errorMessage: String?,
        updatedAt: Date,
        requestedAt: Date
    ) {
        self.status = status
        self.sessionId = sessionId
        self.rawText = rawText
        self.correctedText = correctedText
        self.errorMessage = errorMessage
        self.updatedAt = updatedAt
        self.requestedAt = requestedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(VoiceSessionStatus.self, forKey: .status)
        sessionId = try container.decode(UUID.self, forKey: .sessionId)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText) ?? ""
        correctedText = try container.decodeIfPresent(String.self, forKey: .correctedText) ?? ""
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
            correctedText: "",
            errorMessage: nil,
            updatedAt: now,
            requestedAt: now
        )
    }

    var age: TimeInterval {
        Date().timeIntervalSince(requestedAt)
    }

    /// Text the keyboard should prefer inserting.
    func textForInsert(correctionEnabled: Bool, engine: CorrectionEngine) -> String {
        if correctionEnabled {
            if !correctedText.isEmpty { return correctedText }
            return engine.correct(rawText, enabled: true)
        }
        return rawText
    }
}

/// Durable last result — survives keyboard standby clears so Notes can still insert/paste.
struct LastVoiceResult: Codable, Equatable {
    var sessionId: UUID
    var rawText: String
    var correctedText: String
    var updatedAt: Date

    func textForInsert(correctionEnabled: Bool, engine: CorrectionEngine) -> String {
        if correctionEnabled {
            if !correctedText.isEmpty { return correctedText }
            return engine.correct(rawText, enabled: true)
        }
        return rawText
    }

    var isFresh: Bool {
        Date().timeIntervalSince(updatedAt) < VoiceBridge.lastResultTTL
    }
}

enum VoiceBridge {
    /// Abandon abandoned working sessions (host never completed).
    static let sessionTimeout: TimeInterval = 90
    /// Keep last completed result available for paste/insert.
    static let lastResultTTL: TimeInterval = 10 * 60

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

    static func loadLastResult() -> LastVoiceResult? {
        guard let defaults = AppGroupConstants.sharedDefaults,
              let data = defaults.data(forKey: AppGroupConstants.lastVoiceResultKey),
              let result = try? decoder.decode(LastVoiceResult.self, from: data),
              result.isFresh else {
            return nil
        }
        return result
    }

    @discardableResult
    static func saveLastResult(_ result: LastVoiceResult) -> Bool {
        guard let defaults = AppGroupConstants.sharedDefaults,
              let data = try? encoder.encode(result) else { return false }
        defaults.set(data, forKey: AppGroupConstants.lastVoiceResultKey)
        defaults.synchronize()
        return true
    }

    static func clearLastResult() {
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastVoiceResultKey)
        AppGroupConstants.sharedDefaults?.removeObject(forKey: AppGroupConstants.lastClipboardTextKey)
        AppGroupConstants.sharedDefaults?.synchronize()
    }

    static func saveClipboardText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AppGroupConstants.sharedDefaults?.set(trimmed, forKey: AppGroupConstants.lastClipboardTextKey)
        AppGroupConstants.sharedDefaults?.synchronize()
    }

    static func loadClipboardText() -> String? {
        guard let text = AppGroupConstants.sharedDefaults?
            .string(forKey: AppGroupConstants.lastClipboardTextKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    @discardableResult
    static func beginRequest() -> VoicePayload {
        prepareForNewRequest()
        let now = Date()
        let payload = VoicePayload(
            status: .requesting,
            sessionId: UUID(),
            rawText: "",
            correctedText: "",
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

    static func markReady(sessionId: UUID, rawText: String, correctedText: String) {
        var payload = load()
        payload.status = .ready
        payload.sessionId = sessionId
        payload.rawText = rawText
        payload.correctedText = correctedText
        payload.errorMessage = nil
        payload.updatedAt = Date()
        _ = save(payload)
        _ = saveLastResult(
            LastVoiceResult(
                sessionId: sessionId,
                rawText: rawText,
                correctedText: correctedText,
                updatedAt: Date()
            )
        )
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

    /// Reset session to idle. Does NOT erase last completed result (paste/insert fallback).
    static func clearSession() {
        _ = save(.idle())
    }

    /// Backward-compatible name used by older call sites — session only.
    static func clear() {
        clearSession()
    }

    /// After an insert attempt: drop ready session, keep last result briefly for 「結果を貼る」.
    static func markInserted() {
        clearSession()
    }

    /// User started a brand-new voice take — drop previous leftovers.
    static func prepareForNewRequest() {
        clearLastResult()
    }

    static func isTimedOut(_ payload: VoicePayload) -> Bool {
        switch payload.status {
        case .requesting, .listening:
            return payload.age >= sessionTimeout
        default:
            return false
        }
    }
}
