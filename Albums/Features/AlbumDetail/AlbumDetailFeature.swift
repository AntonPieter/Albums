import Foundation
import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
    @ObservableState
    struct State: Equatable {
        let album: Album
        var detail: AlbumDetail?
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
        case detailResponse(Result<AlbumDetail, any Error>)
    }

    @Dependency(\.deezerClient) var deezerClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                guard state.detail == nil else { return .none }
                return loadDetail(&state)

            case .retryTapped:
                return loadDetail(&state)

            case .detailResponse(.success(let detail)):
                state.detail = detail
                state.status = .loaded
                return .none

            case .detailResponse(.failure(let error)):
                state.status = .failed(error.localizedDescription)
                return .none
            }
        }
    }

    private func loadDetail(_ state: inout State) -> Effect<Action> {
        state.status = .loading
        let id = state.album.id
        return .run { send in
            await send(.detailResponse(Result { try await deezerClient.albumDetail(id) }))
        }
    }
}
