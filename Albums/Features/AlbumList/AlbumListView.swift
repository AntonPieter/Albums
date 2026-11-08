import ComposableArchitecture
import SwiftUI

struct AlbumListView: View {
    @Bindable var store: StoreOf<AlbumListFeature>

    var body: some View {
        content
            .navigationTitle("Albums")
            .searchable(text: $store.query, prompt: "Search albums")
            .task { await store.send(.task).finish() }
    }

    @ViewBuilder
    private var content: some View {
        if store.trimmedQuery.isEmpty {
            chartContent
        } else {
            searchContent
        }
    }

    @ViewBuilder
    private var chartContent: some View {
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
                albumList(store.albums)
            }
        }
    }
    
    @ViewBuilder
    private var searchContent: some View {
        switch store.searchStatus {
        case .idle, .loading:
            ProgressView("Searching")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView(
                "Search failed",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

        case .loaded:
            if store.results.isEmpty {
                ContentUnavailableView.search(text: store.query)
            } else {
                albumList(store.results)
            }
        }
    }
    
    private func albumList(_ albums: [Album]) -> some View {
        List(albums) { album in
            Button {
                store.send(.albumTapped(album))
            } label: {
                AlbumRow(album: album)
            }
            .buttonStyle(.plain)
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

#Preview("Search results") {
    NavigationStack {
        AlbumListView(
            store: Store(
                initialState: AlbumListFeature.State(
                    query: "steven", results: Album.mocks, total: 4, searchStatus: .loaded
                )
            ) {
                AlbumListFeature()
            }
        )
    }
}

#Preview("Search loading") {
    NavigationStack {
        AlbumListView(
            store: Store(
                initialState: AlbumListFeature.State(query: "steven", searchStatus: .loading)
            ) {
                AlbumListFeature()
            }
        )
    }
}

#Preview("Search empty") {
    NavigationStack {
        AlbumListView(
            store: Store(
                initialState: AlbumListFeature.State(query: "zzzz", searchStatus: .loaded)
            ) {
                AlbumListFeature()
            }
        )
    }
}

#Preview("Search error") {
    NavigationStack {
        AlbumListView(
            store: Store(
                initialState: AlbumListFeature.State(
                    query: "steven",
                    searchStatus: .failed("The server sent an invalid response.")
                )
            ) {
                AlbumListFeature()
            }
        )
    }
}
