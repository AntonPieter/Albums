import ComposableArchitecture
import Testing

@testable import Albums

@MainActor
struct AlbumListFeatureTests {
    @Test
    func loadsAlbums() async {
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.charts = { Album.mocks }
        }

        await store.send(.task) {
            $0.status = .loading
        }
        await store.receive(\.albumsResponse.success) {
            $0.albums = Album.mocks
            $0.status = .loaded
        }
    }

    @Test
    func loadingFailureShowsMessage() async {
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.charts = { throw DeezerError.invalidResponse }
        }

        await store.send(.task) {
            $0.status = .loading
        }
        await store.receive(\.albumsResponse.failure) {
            $0.status = .failed("The server sent an invalid response.")
        }
    }

    @Test
    func emptyResultIsLoadedWithoutAlbums() async {
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.charts = { [] }
        }

        await store.send(.task) {
            $0.status = .loading
        }
        await store.receive(\.albumsResponse.success) {
            $0.status = .loaded
        }
    }

    @Test
    func retryLoadsAgainAfterFailure() async {
        let store = TestStore(
            initialState: AlbumListFeature.State(status: .failed("Something went wrong"))
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.charts = { Album.mocks }
        }

        await store.send(.retryTapped) {
            $0.status = .loading
        }
        await store.receive(\.albumsResponse.success) {
            $0.albums = Album.mocks
            $0.status = .loaded
        }
    }
}
