# Project Rules

Check taskList.md for project progress context. Do not check anything off without confirming with me first.

## File Organization
- Keep files small & focused
- One struct/class per file (plus its accompanying extensions).
- Group related code by feature folder:
  - Models/ for pure data types
  - Services/ for API/network logic
  - ViewModels/ for state + business logic
  - Views/ for SwiftUI UI code

## Naming Conventions
- Types: PascalCase (SunsetService, DailyForecast)
- Properties & funcs: camelCase (fetchData, todayCloudMean)
- Prefix async loaders with load / fetch, e.g. loadForecast()

## Function Design
- Small, single‐purpose functions
- Break complex logic into helpers: e.g. indexFor(_:in:) for matching hour.
- View body subsections sit in private var fooView: some View { … }.

## Documentation & Logging
- Every view subsection gets a // MARK: header.
- Complex algorithms get a few lines of explanation right above.
- Verbose, prefixed console logging:
```swift
print("[SunsetService] ▶️ Fetching URL:", url)
print("[ContentView] built \(list.count) days")
print("[FavRow] \(location.displayName) localTime → \(localTime)")
```
- Log both entry and exit of important async tasks.

## Coding Style
- Guard & early return. Avoid deep nesting; prefer:
```swift
guard let coord = location else { return }
```
- Minimal inline styling – Don't sprinkle colors or fonts all over; use them once in a reusable component or extension.

## Architecture
- Explicit dependency injection
- Inject services into view‐models:
```swift
init(service: SunsetServiceProtocol = SunsetService.shared) { … }
```
- Avoid calling singletons directly deep inside views.

## Error Handling
- Catch errors at the top‐level async call, print them, and set a @State var errorMessage for the UI.
- Never swallow errors silently.

## Algorithm Design
- Keep formulas visible & simple
- Write the score algorithm in a dedicated helper with doc comments:
```swift
/// Computes sunset score as average of high/mid/low clouds, clamped 0–100.
func computeSunsetScore(high: Double, mid: Double, low: Double) -> Int { … }
```

## SwiftUI Layout & Safe Areas
- **Header Placement**: When creating full-screen views with headers, place headers in a parent VStack with explicit padding for the safe area, rather than using `.safeAreaInset`. This provides more reliable spacing across devices.
```swift
VStack(spacing: 0) {
    // Header with safe area respect
    headerView
        .padding(.top, geometry.safeAreaInsets.top)
    
    // Main content
    contentView
}
```

- **Safe Area Handling**: Only apply `.ignoresSafeArea()` to background elements (like gradients). Never apply it to content containers like ScrollView.

- **Consistent Content Padding**: Apply consistent padding to ScrollView content with:
```swift
.padding(.top, 32)
.padding(.bottom, 24)
.padding(.horizontal)
```

- **Frame Sizing**: Ensure proper frame sizing of main content containers with:
```swift
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

- **Debugging Tools**: When facing layout issues, add temporary debug visualizations:
```swift
.debugSafeArea(name: "ViewName", color: .red)
.logPadding(name: "ViewName", top: topValue, bottom: bottomValue)
``` 