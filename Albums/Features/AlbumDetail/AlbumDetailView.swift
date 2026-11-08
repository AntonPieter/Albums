import ComposableArchitecture
import SwiftUI

struct AlbumDetailView: View {
    let store: StoreOf<AlbumDetailFeature>

    var body: some View {
        ScrollView {
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
            .padding()
        }
        .navigationTitle(store.album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.task).finish()
        }
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(
            store: Store(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
                AlbumDetailFeature()
            }
        )
    }
}
