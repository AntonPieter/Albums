import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            AlbumListView(store: store.scope(state: \.list, action: \.list))
        } destination: { store in
            switch store.case {
            case .detail(let store):
                AlbumDetailView(store: store)
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State(list: AlbumListFeature.State(albums: Album.mocks))
        ) {
            AppFeature()
        }
    )
}
