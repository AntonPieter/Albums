import ComposableArchitecture

@Reducer
struct AlbumListFeature {
    @ObservableState
    struct State: Equatable {
        var albums: [Album] = []
    }

    enum Action {
        case albumTapped(Album)
        case delegate(Delegate)

        @CasePathable
        enum Delegate: Equatable {
            case albumSelected(Album)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .albumTapped(let album):
                return .send(.delegate(.albumSelected(album)))
            case .delegate:
                return .none
            }
        }
    }
}
