import Foundation

extension Album {
    static let mocks: [Album] = [
        Album(
            id: 1003954251,
            title: "Requiem for a Village",
            artistName: "Steven Wilson",
            coverURL: URL(string: "https://cdn-images.dzcdn.net/images/cover/a5e7401fc2c323a6a16ac37f1436ebfb/1000x1000-000000-80-0-0.jpg")
        ),
        Album(
            id: 1076534322,
            title: "Stray Dogs",
            artistName: "Nothing But Thieves",
            coverURL: URL(string: "https://cdn-images.dzcdn.net/images/cover/c4b708c1349a7d885439a520fa45bace/1000x1000-000000-80-0-0.jpg")
        ),
        Album(
            id: 453077805,
            title: "Time and Again",
            artistName: "The Bowery",
            coverURL: URL(string: "https://cdn-images.dzcdn.net/images/cover/ce733a99cb4390075331ace95a2d7a0f/1000x1000-000000-80-0-0.jpg")
        ),
        Album(
            id: 7848265,
            title: "Stay Gold",
            artistName: "First Aid Kit",
            coverURL: URL(string: "https://cdn-images.dzcdn.net/images/cover/47beac9dc340e15af33614ca382a90f6/1000x1000-000000-80-0-0.jpg")
        ),
    ]
}

extension AlbumDetail {
    static let mock = AlbumDetail(
        releaseDate: "2025-01-01",
        label: "Sample Label",
        trackCount: 3,
        duration: 780,
        genres: ["Rock"],
        tracks: [
            Track(id: 1, title: "Sample Track One", duration: 240),
            Track(id: 2, title: "Sample Track Two", duration: 270),
            Track(id: 3, title: "Sample Track Three", duration: 270),
        ]
    )
}
