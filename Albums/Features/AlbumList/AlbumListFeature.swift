import ComposableArchitecture
import Foundation

@Reducer
struct AlbumListFeature {
    @ObservableState
    struct State: Equatable {
        var albums: [Album] = []
        var status: Status = .idle

        enum Status: Equatable {
            case idle
            case loading
            case loaded
            case failed(String)
        }
    }

    enum Action {
        case task
        case retryTapped
        case albumsResponse(Result<[Album], any Error>)
        case albumTapped(Album)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case albumSelected(Album)
        }
    }

    @Dependency(\.deezerClient) var deezerClient

    var body: some ReducerOf<Self> {
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
