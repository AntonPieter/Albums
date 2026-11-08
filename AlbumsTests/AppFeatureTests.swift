import ComposableArchitecture
import Testing

@testable import Albums

@MainActor
struct AppFeatureTests {
    @Test
    func tappingAlbumPushesDetail() async {
        let album = Album.mocks[0]
        let store = TestStore(
            initialState: AppFeature.State(list: AlbumListFeature.State(albums: Album.mocks))
        ) {
            AppFeature()
        }

        await store.send(\.list.albumTapped, album)
        await store.receive(\.list.delegate.albumSelected, album) {
            $0.path[id: 0] = .detail(AlbumDetailFeature.State(album: album))
        }
    }
}
