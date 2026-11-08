import Foundation

struct Album: Equatable, Identifiable, Sendable {
    let id: Int
    let title: String
    let artistName: String
    let coverURL: URL?
}

// Decodable lives in an extension. The memberwise init stays available for mocks.
extension Album: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, artist
        case cover = "cover_xl"
    }

    private struct Artist: Decodable {
        let name: String
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artistName = try container.decode(Artist.self, forKey: .artist).name
        coverURL = try container
            .decodeIfPresent(String.self, forKey: .cover)
            .flatMap { URL(string: $0) }
    }
}
