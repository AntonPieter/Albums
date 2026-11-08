import ComposableArchitecture
import SwiftUI

@main
struct AlbumsApp: App {
    static let store = Store(
        initialState: AppFeature.State(list: AlbumListFeature.State(albums: Album.mocks))
    ) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
