import ComposableArchitecture
import Foundation

@Reducer
struct AlbumListFeature {
    @ObservableState
    struct State: Equatable {
        var albums: [Album] = []
        var status: Status = .idle
        var query = ""
        var results: [Album] = []
        var total: Int?
        var searchStatus: Status = .idle
        var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }
        var isLoadingMore = false
        var loadMoreFailed = false

        var canLoadMore: Bool {
            guard searchStatus == .loaded, !isLoadingMore, !loadMoreFailed, let total else {
                return false
            }
            return results.count < total
        }
        
        enum Status: Equatable {
            case idle
            case loading
            case loaded
            case failed(String)
        }
    }
    
    enum Action: BindableAction {
        case task
        case retryTapped
        case albumsResponse(Result<[Album], any Error>)
        case albumTapped(Album)
        case delegate(Delegate)
        case binding(BindingAction<State>)
        case searchResponse(Result<Page<Album>, any Error>)
        case loadMore
        case loadMoreRetryTapped
        case loadMoreResponse(Result<Page<Album>, any Error>)
        
        @CasePathable
        enum Delegate: Equatable {
            case albumSelected(Album)
        }
    }
    
    private enum CancelID { case search }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.deezerClient) var deezerClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .task:
                guard state.albums.isEmpty else { return .none }
                return loadCharts(&state)
                
            case .retryTapped:
                return loadCharts(&state)
                
            case .albumsResponse(.success(let albums)):
                state.albums = albums
                state.status = .loaded
                return .none
                
            case .albumsResponse(.failure(let error)):
                state.status = .failed(error.localizedDescription)
                return .none
                
            case .albumTapped(let album):
                return .send(.delegate(.albumSelected(album)))
                
            case .delegate:
                return .none
                
            case .binding(\.query):
                state.isLoadingMore = false
                state.loadMoreFailed = false
                let query = state.trimmedQuery
                guard !query.isEmpty else {
                    state.results = []
                    state.total = nil
                    state.searchStatus = .idle
                    return .cancel(id: CancelID.search)
                }
                state.searchStatus = .loading
                return .run { send in
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchResponse(Result { try await deezerClient.search(query, 0) }))
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)
                
            case .binding:
                return .none
                
            case .searchResponse(.success(let page)):
                state.results = page.data
                state.total = page.total
                state.searchStatus = .loaded
                return .none
                
            case .searchResponse(.failure(let error)):
                state.searchStatus = .failed(error.localizedDescription)
                return .none
                
            case .loadMore:
                guard state.canLoadMore else { return .none }
                return loadNextPage(&state)

            case .loadMoreRetryTapped:
                guard state.loadMoreFailed else { return .none }
                state.loadMoreFailed = false
                return loadNextPage(&state)

            case .loadMoreResponse(.success(let page)):
                state.isLoadingMore = false
                state.results.append(contentsOf: page.data)
                // Empty page means there is nothing more. This prevents an infinite loop.
                state.total = page.data.isEmpty ? state.results.count : (page.total ?? state.total)
                return .none

            case .loadMoreResponse(.failure):
                state.isLoadingMore = false
                state.loadMoreFailed = true
                return .none
            }
        }
    }
    
    private func loadCharts(_ state: inout State) -> Effect<Action> {
        state.status = .loading
        return .run { send in
            await send(.albumsResponse(Result { try await deezerClient.charts() }))
        }
    }
    
    private func loadNextPage(_ state: inout State) -> Effect<Action> {
        state.isLoadingMore = true
        let query = state.trimmedQuery
        let index = state.results.count
        return .run { send in
            await send(.loadMoreResponse(Result { try await deezerClient.search(query, index) }))
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)
    }
}
