import ComposableArchitecture
import Foundation

@DependencyClient
struct DeezerClient {
    var charts: @Sendable () async throws -> [Album]
    var search: @Sendable (_ query: String, _ index: Int) async throws -> Page<Album>
    var albumDetail: @Sendable (_ id: Int) async throws -> AlbumDetail
}

extension DependencyValues {
    var deezerClient: DeezerClient {
        get { self[DeezerClient.self] }
        set { self[DeezerClient.self] = newValue }
    }
}

extension DeezerClient: DependencyKey {
    static let liveValue = DeezerClient(
        charts: {
            try await DeezerAPI.get(
                "chart/0/albums",
                query: [URLQueryItem(name: "limit", value: "50")],
                as: Page<Album>.self
            ).data
        },
        search: { query, index in
            try await DeezerAPI.get(
                "search/album",
                query: [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "index", value: String(index)),
                ],
                as: Page<Album>.self
            )
        },
        albumDetail: { id in
            try await DeezerAPI.get("album/\(id)", as: AlbumDetail.self)
        }
    )

    static let previewValue = DeezerClient(
        charts: { Album.mocks },
        search: { query, index in
            let matches = Album.mocks.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                    || $0.artistName.localizedCaseInsensitiveContains(query)
            }
            return Page(data: index == 0 ? matches : [], total: matches.count)
        },
        albumDetail: { _ in .mock }
    )

    // Every endpoint reports an issue when a test calls it without an override.
    static let testValue = DeezerClient()
}

enum DeezerError: Error, Equatable, LocalizedError {
    case invalidResponse
    case server(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server sent an invalid response."
        case .server(let message): message
        }
    }
}

private enum DeezerAPI {
    static func get<Value: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        as type: Value.Type
    ) async throws -> Value {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.deezer.com"
        components.path = "/" + path
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw DeezerError.invalidResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else { throw DeezerError.invalidResponse }

        // Deezer can report an error inside a normal JSON body.
        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
            throw DeezerError.server(message: envelope.error.message)
        }
        return try JSONDecoder().decode(Value.self, from: data)
    }

    private struct ErrorEnvelope: Decodable {
        struct Body: Decodable { let message: String }
        let error: Body
    }
}
