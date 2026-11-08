import ComposableArchitecture
import Testing

@testable import Albums

@MainActor
struct AlbumDetailFeatureTests {
    
    @Test
    func loadsDetail() async {
        let store = TestStore(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
            AlbumDetailFeature()
        } withDependencies: {
            $0.deezerClient.albumDetail = { _ in .mock }
        }
        
        await store.send(.task) {
            $0.status = .loading
        }
        
        await store.receive(\.detailResponse.success) {
            $0.detail = .mock
            $0.status = .loaded
        }
        
    }
    
    @Test
    func loadingFailureShowsMessage() async {
        let store = TestStore(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
            AlbumDetailFeature()
        } withDependencies: {
            $0.deezerClient.albumDetail = { _ in throw DeezerError.invalidResponse }
        }

        await store.send(.task) {
            $0.status = .loading
        }
        
        await store.receive(\.detailResponse.failure) {
            $0.status = .failed("The server sent an invalid response.")
        }
    }
    
    @Test
    func retryLoadsAgainAfterFailure() async {
        let store = TestStore(initialState: AlbumDetailFeature.State(album: Album.mocks[0])) {
            AlbumDetailFeature()
        } withDependencies: {
            $0.deezerClient.albumDetail = { _ in throw DeezerError.invalidResponse }
        }
        
        await store.send(.task) {
            $0.status = .loading
        }
        
        await store.receive(\.detailResponse.failure) {
            $0.status = .failed("The server sent an invalid response.")
        }
        
        store.dependencies.deezerClient.albumDetail = { _ in .mock }
        
        await store.send(.retryTapped) {
            $0.status = .loading
        }
        
        await store.receive(\.detailResponse.success) {
            $0.detail = .mock
            $0.status = .loaded
        }
    }
}
