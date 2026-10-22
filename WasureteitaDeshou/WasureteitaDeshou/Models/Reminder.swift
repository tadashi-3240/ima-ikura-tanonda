import Foundation

/// 端末内に保存する予定（第2段階）。位置通知は第3段階。
struct Reminder: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var placeName: String
    var address: String
    var task: String
    var latitude: Double
    var longitude: Double
    var rawUtterance: String
    var createdAt: Date
    /// 第3段階で本実装。枠のみ保持（初期 1000m）。
    var notifyDistanceMeters: Int

    init(
        id: UUID = UUID(),
        placeName: String,
        address: String,
        task: String,
        latitude: Double,
        longitude: Double,
        rawUtterance: String,
        createdAt: Date = Date(),
        notifyDistanceMeters: Int = 1000
    ) {
        self.id = id
        self.placeName = placeName
        self.address = address
        self.task = task
        self.latitude = latitude
        self.longitude = longitude
        self.rawUtterance = rawUtterance
        self.createdAt = createdAt
        self.notifyDistanceMeters = notifyDistanceMeters
    }
}
