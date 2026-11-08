import Foundation

struct AlbumDetail: Equatable, Sendable {
    let releaseDate: String?
    let label: String?
    let trackCount: Int
    let duration: Int
    let genres: [String]
    let tracks: [Track]

    struct Track: Equatable, Identifiable, Sendable, Decodable {
        let id: Int
        let title: String
        let duration: Int
    }
}

extension AlbumDetail: Decodable {
    private enum CodingKeys: String, CodingKey {
        case label, duration, genres, tracks
        case releaseDate = "release_date"
        case trackCount = "nb_tracks"
    }

    private struct Genre: Decodable {
        let name: String
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        trackCount = try container.decodeIfPresent(Int.self, forKey: .trackCount) ?? 0
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 0
        genres = try container.decodeIfPresent(Page<Genre>.self, forKey: .genres)?.data.map(\.name) ?? []
        tracks = try container.decodeIfPresent(Page<Track>.self, forKey: .tracks)?.data ?? []
    }
}
