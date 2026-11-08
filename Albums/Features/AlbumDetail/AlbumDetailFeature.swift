import ComposableArchitecture

@Reducer
struct AlbumDetailFeature {
    @ObservableState
    struct State: Equatable {
        let album: Album
    }

    enum Action {
        case task
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .task:
                return .none
            }
        }
    }
}
