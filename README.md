# Albums

Small iOS app built with SwiftUI and The Composable Architecture (TCA).
It shows popular albums from the Deezer API.

## Build and run

- Xcode 27.2
- iOS 17.0 or later, iPhone only
- Open `Albums.xcodeproj` and run on an iPhone simulator.
- No API key is needed.
- No signing is needed for the simulator.

## API

Deezer public API (no key).
Why: no key, large cover art, and music fits my background.
Endpoints: to be filled in.

## Feature structure

```
Albums/
  App/                   AppFeature (parent, owns the StackState) and AppView
  Features/AlbumList/    list feature and view
  Features/AlbumDetail/  detail feature and view
  Models/                Album, AlbumDetail, Page, mock data
AlbumsTests/             tests for the features
```

State flow:

1. `AlbumListFeature` sends `.delegate(.albumSelected(album))` when a row is tapped.
2. `AppFeature` handles the delegate action and pushes `AlbumDetailFeature` onto its `StackState`.
3. `AlbumDetailFeature` starts with the album it received.

The list feature does not know about the detail feature. Only the parent connects them.

## Trade-offs

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

## With more time

- Mocks live in the app target. I would wrap them in `#if DEBUG` or move them
  to a separate module.
- Separate DTOs for the API, mapped to domain models.
- Split the app into Swift packages (for example `Models`, `DeezerClient`,
  `Features`) so the compiler enforces the boundaries.

## AI tools

To be filled in.
