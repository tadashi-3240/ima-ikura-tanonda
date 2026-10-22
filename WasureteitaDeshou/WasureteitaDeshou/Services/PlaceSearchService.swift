import CoreLocation
import Foundation
import MapKit

enum PlaceSearchError: LocalizedError {
    case emptyQuery
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "検索する場所の言葉が空です。"
        case .failed(let message):
            return message
        }
    }
}

/// Apple MapKit による店舗・場所検索。
@MainActor
final class PlaceSearchService {
    private let geocoder = CLGeocoder()

    func search(query: String, near userLocation: CLLocationCoordinate2D? = nil) async throws -> [PlaceCandidate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { throw PlaceSearchError.emptyQuery }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        request.resultTypes = [.pointOfInterest, .address]
        if let userLocation {
            let region = MKCoordinateRegion(
                center: userLocation,
                latitudinalMeters: 40_000,
                longitudinalMeters: 40_000
            )
            request.region = region
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            let mapped = response.mapItems.map(PlaceCandidate.init(mapItem:))
            return deduplicated(mapped)
        } catch {
            throw PlaceSearchError.failed("場所の検索に失敗しました。通信環境を確認してください。")
        }
    }

    /// 地図で選んだ座標から住所・名前を補完する。
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> PlaceCandidate {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            let mark = marks.first
            let name = [
                mark?.name,
                mark?.thoroughfare
            ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
            ?? "地図で選んだ場所"

            let address = [
                mark?.administrativeArea,
                mark?.locality,
                mark?.thoroughfare,
                mark?.subThoroughfare
            ]
            .compactMap { $0 }
            .joined(separator: "")

            return PlaceCandidate(
                name: name,
                address: address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            return PlaceCandidate(
                name: "地図で選んだ場所",
                address: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    }

    private func deduplicated(_ items: [PlaceCandidate]) -> [PlaceCandidate] {
        var seen = Set<String>()
        var result: [PlaceCandidate] = []
        for item in items {
            let key = "\(item.name)|\(String(format: "%.4f", item.latitude))|\(String(format: "%.4f", item.longitude))"
            if seen.insert(key).inserted {
                result.append(item)
            }
        }
        return result
    }
}
