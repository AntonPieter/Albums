import ComposableArchitecture
import SwiftUI

struct AlbumDetailView: View {
    let store: StoreOf<AlbumDetailFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                content
            }
            .padding()
        }
        .navigationTitle(store.album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.task).finish()
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            AsyncImage(url: store.album.coverURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Color.secondary.opacity(0.2)
                    .aspectRatio(1, contentMode: .fit)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(store.album.title).font(.title2.bold())
            Text(store.album.artistName).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.status {
        case .idle, .loading:
            ProgressView()
                .padding(.top, 24)

        case .failed(let message):
            ContentUnavailableView {
                Label("Could not load album", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { store.send(.retryTapped) }
            }

        case .loaded:
            if let detail = store.detail {
                DetailInfo(detail: detail)
            }
        }
    }
}

private struct DetailInfo: View {
    let detail: AlbumDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let releaseDate = detail.releaseDate {
                Text(releaseDate)
            }
            if let label = detail.label {
                Text(label)
            }
            if !detail.genres.isEmpty {
                Text(detail.genres.joined(separator: ", "))
            }

            Divider()

            ForEach(Array(detail.tracks.enumerated()), id: \.element.id) { index, track in
                HStack {
                    Text("\(index + 1)")
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                    Text(track.title)
                    Spacer()
                    Text(Self.format(track.duration))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func format(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}

#Preview("Loaded") {
    NavigationStack {
        AlbumDetailView(
            store: Store(
                initialState: AlbumDetailFeature.State(
                    album: Album.mocks[0], detail: .mock, status: .loaded
                )
            ) {
                AlbumDetailFeature()
            }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        AlbumDetailView(
            store: Store(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
                AlbumDetailFeature()
            } withDependencies: {
                $0.deezerClient.albumDetail = { _ in
                    try await Task.sleep(for: .seconds(3600))
                    return .mock
                }
            }
        )
    }
}

#Preview("Error") {
    NavigationStack {
        AlbumDetailView(
            store: Store(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
                AlbumDetailFeature()
            } withDependencies: {
                $0.deezerClient.albumDetail = { _ in throw DeezerError.invalidResponse }
            }
        )
    }
}
