# Albums

Small iOS app built with SwiftUI and The Composable Architecture (TCA).
It shows popular albums from the Deezer API.

## Build and run

- Xcode 27.2
- iOS 17.0 or later, iPhone only
- Open `Albums.xcodeproj` and run on an iPhone simulator.
- No API key is needed.
- No signing is needed for the simulator.
- Xcode asks to trust the TCA macros on the first build. Choose Trust & Enable.

## API

Deezer public API (no key).

Why: no key, large cover art, and music fits my background.

Endpoints:

- `GET /chart/0/albums?limit=50` (list, the chart returns at most 50 albums)
- `GET /search/album?q=&index=` (search, 25 albums per page, `index` is the offset)
- `GET /album/{id}` (detail with tracks, genres, label and release date)

## Feature structure

```
Albums/
  App/                   AppFeature (parent, owns the StackState) and AppView
  Clients/               DeezerClient (live, preview and test values)
  Features/AlbumList/    list feature and view
  Features/AlbumDetail/  detail feature and view
  Models/                Album, AlbumDetail, Page, mock data
AlbumsTests/             tests for the features
```

State flow:
State flow:

1. `AlbumListFeature` loads the chart through `DeezerClient`. When the search
   field has text, it searches instead.
2. Search waits 300 ms after the last key press (debounce). A new key press
   cancels the pending request.
3. When the last search result appears, the list asks for the next page
   (`index = results.count`). It stops when all results are loaded.
4. `AlbumListFeature` sends `.delegate(.albumSelected(album))` when a row is tapped.
5. `AppFeature` handles the delegate action and pushes `AlbumDetailFeature`
   onto its `StackState`.
6. `AlbumDetailFeature` starts with the album it received. It then loads the
   tracks, label and genres.

The list feature does not know about the detail feature. Only the parent connects them.

## Testing and previews

- The views have previews for loading, loaded and error states. The list also
  has previews for empty states. The previews use mock data.
- `DeezerClient` has a `previewValue` with mock data. Its `testValue` fails
  when a test calls an endpoint it did not set up.
- Reducer tests use `TestStore`. The search tests use `TestClock` to test the
  debounce. Run the tests with Cmd+U.

## Decisions and trade-offs

- Project format: classic Property List (`project.pbxproj`). The Xcode 27.2
  template created the new JSON format (`.xcproj`), which needs Xcode 27 or
  later. Property List is the widely supported format. Compatibility is set to
  Xcode 27.0.
- Swift 6 language mode with Default Actor Isolation set to `nonisolated`.
  Reason: models and dependencies stay free of implicit MainActor isolation.
- iPhone only, deployment target iOS 17. Reason: small scope.
- TCA 1.26.2 via Swift Package Manager. It is the only direct dependency. TCA
  brings its own Point-Free packages and swift-syntax. `Package.resolved` is
  committed, so the versions are pinned.
- `Album` and `AlbumDetail` serve as API models and domain models. Reason: fewer
  types for a small app.
- The chart endpoint has no next page, so the list loads 50 albums at once.
  Search has real pagination through `index`, so paging lives in the search.
- Loading state is one `Status` enum. `albums` is a separate array, so a later
  refresh or search paging can keep showing the old albums. The cost: the enum
  alone does not make every invalid combination impossible.
- The list loads the chart once. Going back from the detail screen does not
  reload it. No pull-to-refresh for now.
- The detail screen shows the album from the list at once. Only the extra data (tracks, label, genres) loads and can fail.
- Search shows a spinner and replaces the list on every new query. The cost:
  the screen flickers while the user types.
- Paging trusts `total` from the API. An empty page also stops the paging, so a
  wrong `total` cannot cause an endless loop.
- Nothing is cached. Reason: small scope.

## With more time

- Mocks live in the app target. I would wrap them in `#if DEBUG` or move them
  to a separate module.
- Separate DTOs for the API, mapped to domain models.
- Split the app into Swift packages (for example `Models`, `DeezerClient`,
  `Features`) so the compiler enforces the boundaries.
- Pull to refresh for the chart.
- Keep the old results visible while a new search loads.
- Cache album details.
- UI tests and snapshot tests.
- More accessibility work, such as testing with VoiceOver and Dynamic Type.

## AI tools

To be filled in.
