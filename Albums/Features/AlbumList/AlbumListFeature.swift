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
            }
        }
    }
    
    private func loadCharts(_ state: inout State) -> Effect<Action> {
        state.status = .loading
        return .run { send in
            await send(.albumsResponse(Result { try await deezerClient.charts() }))
        }
    }
}
