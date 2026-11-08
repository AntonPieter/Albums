import ComposableArchitecture
import SwiftUI

struct AlbumListView: View {
    let store: StoreOf<AlbumListFeature>

    var body: some View {
        content
            .navigationTitle("Albums")
            .task { await store.send(.task).finish() }
    }

    @ViewBuilder
    private var content: some View {
        switch store.status {
        case .idle, .loading:
            ProgressView("Loading albums")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView {
                Label("Could not load albums", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { store.send(.retryTapped) }
            }

        case .loaded:
            if store.albums.isEmpty {
                ContentUnavailableView("No albums", systemImage: "music.note.list")
            } else {
                List(store.albums) { album in
                    Button {
                        store.send(.albumTapped(album))
                    } label: {
                        AlbumRow(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: album.coverURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading) {
                Text(album.title).font(.headline)
                Text(album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Loaded") {
    NavigationStack {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State()) {
                AlbumListFeature()
            }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State()) {
                AlbumListFeature()
            } withDependencies: {
                $0.deezerClient.charts = {
                    try await Task.sleep(for: .seconds(3600))
                    return []
                }
            }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State()) {
                AlbumListFeature()
            } withDependencies: {
                $0.deezerClient.charts = { [] }
            }
        )
    }
}

#Preview("Error") {
    NavigationStack {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State()) {
                AlbumListFeature()
            } withDependencies: {
                $0.deezerClient.charts = { throw DeezerError.invalidResponse }
            }
        )
    }
}
