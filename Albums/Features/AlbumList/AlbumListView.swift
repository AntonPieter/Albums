//
//  AlbumListView.swift
//  Albums
//
//  Created by AP van Grootel on 08/11/2026.
//


import ComposableArchitecture
import SwiftUI

struct AlbumListView: View {
    let store: StoreOf<AlbumListFeature>

    var body: some View {
        List(store.albums) { album in
            Button {
                store.send(.albumTapped(album))
            } label: {
                AlbumRow(album: album)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Albums")
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

#Preview {
    NavigationStack {
        AlbumListView(
            store: Store(initialState: AlbumListFeature.State(albums: Album.mocks)) {
                AlbumListFeature()
            }
        )
    }
}
