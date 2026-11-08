import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var list = AlbumListFeature.State()
        var path = StackState<Path.State>()
    }

    enum Action {
        case list(AlbumListFeature.Action)
        case path(StackActionOf<Path>)
    }

    @Reducer
    enum Path {
        case detail(AlbumDetailFeature)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.list, action: \.list) {
            AlbumListFeature()
        }
        Reduce { state, action in
            switch action {
            case .list(.delegate(.albumSelected(let album))):
                state.path.append(.detail(AlbumDetailFeature.State(album: album)))
                return .none
            case .list, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension AppFeature.Path.State: Equatable {}
