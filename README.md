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

To be filled in.

## Trade-offs

- Project format: classic Property List (`project.pbxproj`) instead of the new
  JSON format (`.xcproj`). Reason: it opens in older Xcode versions too.
- Swift 6 language mode with Default Actor Isolation set to `nonisolated`.
  Reason: models and the API client stay free of implicit MainActor isolation.
- iPhone only, deployment target iOS 17. Reason: small scope.
- TCA 1.26.2, added with Swift Package Manager. No other third-party dependencies.

## With more time

To be filled in.

## AI tools

To be filled in.
