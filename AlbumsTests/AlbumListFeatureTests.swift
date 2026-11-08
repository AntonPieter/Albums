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
    
    @Test
    func searchLoadsFirstPageAfterDebounce() async {
        let clock = TestClock()
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.deezerClient.search = { _, _ in Page(data: Album.mocks, total: 4) }
        }
        
        await store.send(.binding(.set(\.query, "steven"))) {
            $0.query = "steven"
            $0.searchStatus = .loading
        }
        await clock.advance(by: .milliseconds(300))
        await store.receive(\.searchResponse.success) {
            $0.results = Album.mocks
            $0.total = 4
            $0.searchStatus = .loaded
        }
    }
    
    @Test
    func typingDuringDebounceSearchesOnlyLastQuery() async {
        let clock = TestClock()
        let queries = LockIsolated<[String]>([])
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.deezerClient.search = { query, _ in
                queries.withValue { $0.append(query) }
                return Page(data: Album.mocks, total: 4)
            }
        }
        
        await store.send(.binding(.set(\.query, "st"))) {
            $0.query = "st"
            $0.searchStatus = .loading
        }
        await clock.advance(by: .milliseconds(100))
        
        await store.send(.binding(.set(\.query, "ste"))) {
            $0.query = "ste"
        }
        await clock.advance(by: .milliseconds(300))
        
        await store.receive(\.searchResponse.success) {
            $0.results = Album.mocks
            $0.total = 4
            $0.searchStatus = .loaded
        }
        
        #expect(queries.value == ["ste"])
    }
    
    @Test
    func clearingQueryDuringDebounceCancelsSearch() async {
        let clock = TestClock()
        let queries = LockIsolated<[String]>([])
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.deezerClient.search = { query, _ in
                queries.withValue { $0.append(query) }
                return Page(data: Album.mocks, total: 4)
            }
        }
        
        await store.send(.binding(.set(\.query, "ste"))) {
            $0.query = "ste"
            $0.searchStatus = .loading
        }
        await clock.advance(by: .milliseconds(100))
        
        await store.send(.binding(.set(\.query, ""))) {
            $0.query = ""
            $0.searchStatus = .idle
        }
        await clock.advance(by: .milliseconds(300))
        
        #expect(queries.value.isEmpty)
    }
    
    @Test
    func searchFailureShowsMessage() async {
        let clock = TestClock()
        let store = TestStore(initialState: AlbumListFeature.State()) {
            AlbumListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.deezerClient.search = { _, _ in throw DeezerError.invalidResponse }
        }
        
        await store.send(.binding(.set(\.query, "error"))) {
            $0.query = "error"
            $0.searchStatus = .loading
        }
        await clock.advance(by: .milliseconds(300))
        
        await store.receive(\.searchResponse.failure) {
            $0.searchStatus = .failed("The server sent an invalid response.")
        }
    }
    
    @Test
    func loadMoreAppendsNextPage() async {
        let first = Array(Album.mocks.prefix(2))
        let second = Array(Album.mocks.suffix(2))
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven", results: first, total: 4, searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.search = { _, index in
                Page(data: index == 2 ? second : [], total: 4)
            }
        }
        
        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }
        await store.receive(\.loadMoreResponse.success) {
            $0.results = Album.mocks
            $0.isLoadingMore = false
        }
    }
    
    @Test
    func loadMoreDoesNothingWhenAllLoaded() async {
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven", results: Album.mocks, total: 4, searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        }
        
        await store.send(.loadMore)
    }
    
    @Test
    func loadMoreDoesNothingWhenTriggeredTwice() async {
        let clock = TestClock()
        let calls = LockIsolated(0)
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven",
                results: Array(Album.mocks.prefix(2)),
                total: 4,
                searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.search = { _, _ in
                calls.withValue { $0 += 1 }
                try await clock.sleep(for: .seconds(1))
                return Page(data: Array(Album.mocks.suffix(2)), total: 4)
            }
        }
        
        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }
        await store.send(.loadMore)
        
        await clock.advance(by: .seconds(1))
        await store.receive(\.loadMoreResponse.success) {
            $0.results = Album.mocks
            $0.isLoadingMore = false
        }
        
        #expect(calls.value == 1)
    }
    
    @Test
    func emptyPageStopsFurtherLoading() async {
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven",
                results: Array(Album.mocks.prefix(2)),
                total: 10,
                searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.search = { _, _ in Page(data: [], total: 10) }
        }
        
        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }
        await store.receive(\.loadMoreResponse.success) {
            $0.isLoadingMore = false
            $0.total = 2
        }
        
        await store.send(.loadMore)
    }
    
    @Test
    func loadMoreRetryAppendsNextPageAfterFailure() async {
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven",
                results: Array(Album.mocks.prefix(2)),
                total: 10,
                searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.deezerClient.search = { _, _ in throw DeezerError.invalidResponse }
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }
        await store.receive(\.loadMoreResponse.failure) {
            $0.isLoadingMore = false
            $0.loadMoreFailed = true
        }

        store.dependencies.deezerClient.search = { _, _ in
            Page(data: Array(Album.mocks.suffix(2)), total: 10)
        }

        await store.send(.loadMoreRetryTapped) {
            $0.loadMoreFailed = false
            $0.isLoadingMore = true
        }
        await store.receive(\.loadMoreResponse.success) {
            $0.isLoadingMore = false
            $0.results = Album.mocks
        }
    }
    
    @Test
    func newQueryDuringLoadMoreCancelsLoadMore() async {
        let clock = TestClock()
        let queries = LockIsolated<[String]>([])
        let store = TestStore(
            initialState: AlbumListFeature.State(
                query: "steven",
                results: Array(Album.mocks.prefix(2)),
                total: 10,
                searchStatus: .loaded
            )
        ) {
            AlbumListFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.deezerClient.search = { query, index in
                queries.withValue { $0.append("\(query)@\(index)") }
                if index > 0 {
                    try await clock.sleep(for: .seconds(10))
                }
                return Page(data: Array(Album.mocks.suffix(2)), total: 10)
            }
        }

        await store.send(.loadMore) {
            $0.isLoadingMore = true
        }
        
        await store.send(.binding(.set(\.query, "wilson"))) {
            $0.query = "wilson"
            $0.searchStatus = .loading
            $0.isLoadingMore = false
        }
        await clock.advance(by: .milliseconds(300))
        
        await store.receive(\.searchResponse.success) {
            $0.results = Array(Album.mocks.suffix(2))
            $0.searchStatus = .loaded
        }
        
        #expect(queries.value == ["steven@2", "wilson@0"])
    }
}
