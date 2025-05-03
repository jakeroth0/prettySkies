PrettySkies / SunsetForecast
🏆 Project Purpose
An iOS app (SwiftUI + CoreLocation) that tells you how dramatic tonight’s sunset will be, based on real-time and forecast weather data. You get:

A “sunset score” (0–100%) for today (+ next 9 days)

Key variables (cloud cover layers, humidity, AOD) at golden hour

Local times for golden hour & sunset

A gradient background whose vibrancy tracks your score

Ability to search for any city, favorite it, and swipe between locations

📁 Project Structure
ruby
Copy
Edit
SunsetForecast/
├── Models/
│   ├── Location.swift            # lat/lon, displayName, timezone
│   └── ForecastResponse.swift    # RawDaily + RawHourly structs
├── Services/
│   ├── SunsetService.swift       # fetchData(...) → ForecastResponse
│   ├── LocationSearchService.swift
│   └── OpenMeteoSearchService.swift
├── ViewModels/
│   └── SearchViewModel.swift     # manages geocoding search
├── Views/
│   ├── ContentView.swift         # “Home” — current location UI
│   ├── SearchView.swift          # modal search + add-favorite
│   ├── FavoritesView.swift       # list of favorite locations
│   └── LocationDetailView.swift  # full-screen detail for any location
├── Location/
│   └── LocationManager.swift     # wraps CoreLocation, publishes coords
├── Helpers/
│   ├── Color+Hex.swift           # `init(hex:)` extension
│   └── Comparable+Clamp.swift    # `clamped(to:)` extension
├── Assets.xcassets/              # colors & icons
└── SunsetForecastApp.swift       # @main, injects environment objects
🎨 UI Overview
Home (ContentView)

Full-screen gradient (three hex colors), darker at top

“My Location” header + resolved city/state

Huge “score%” label

“Golden HH:MM” & “Sunset HH:MM” times below

Frosted-glass card: 4 variables (Clouds, High-cloud, Humidity, AOD) with SF symbols

Frosted-glass “10-Day Forecast” bar chart

Search (SearchView)

Black background, big “Sunsets” title

Rounded TextField + real-time suggestions from geocoding API

Tap a suggestion to add to favorites & dismiss

Favorites (FavoritesView)

Black background, “Sunsets” header + search button

“My Location” card at top → taps refresh your GPS view

Tappable cards for each saved city showing its name, local time, and today’s score

Detail (LocationDetailView)

Same gradient as home

City header + today’s sunset card (time only for now)

(Later will mirror Home with full 4-variable grid + 10-day bars)

🔗 Data Flow
LocationManager

On init & on demand, requests permission & one-shot location

Publishes coordinate: CLLocationCoordinate2D?

ContentView

.onReceive(locationManager.$coordinate) → new coords

Calls SunsetService.shared.fetchData(for:today, lat:lon)

SunsetService.fetchData

Builds two Open-Meteo URLs:

Weather: 10-day daily(sunset,cloudcover_mean) + hourly(cloudcover_high,cloudcover_mid,cloudcover_low,relativehumidity_2m)

Air: 1-day hourly(aerosol_optical_depth)

Parses JSON into ForecastResponse (with nested RawDaily + RawHourly)

Decoding → UI

DailyForecast array (Date + abbreviated weekday + score)

Day 0 score = avg of 3 cloud layers at hour-of-sunset

Day 1–9 score = 100 − mean daily cloudcover

Today’s details (first element): todayCloudMean, todayHighCloud, todayRh, todayAod, sunsetMoment, goldenMoment

Search + Favorites

SearchViewModel calls OpenMeteoSearchService.search(query) → [Location]

User taps → vm.selectLocation(group) builds a Location (with timeZoneIdentifier)

Adds into FavoritesStore (persisted via UserDefaults)

FavoritesView iterates store and, for each, uses FavRow to display live localTime (with that tz) + kicks off its own SunsetService.shared.fetchData to recompute just today’s score

⚙️ Key Types
swift
Copy
Edit
struct Location: Identifiable, Codable, Hashable {
  let id: String                // “lat,lon”
  let name: String              // city
  let latitude, longitude: Double
  let country: String
  let admin1: String?           // state / region
  let timeZoneIdentifier: String

  var displayName: String { … } // “City, State, Country”
  var timeZone: TimeZone? { … }
}

struct ForecastResponse: Codable {
  let daily: RawDaily
  let hourly: RawHourly
}

struct RawDaily: Codable {
  let time: [String], sunset: [String], cloudcover_mean: [Double]
}
struct RawHourly: Codable {
  let time: [String]
  let cloudCoverHigh, cloudCoverMid, cloudCoverLow: [Double]
  let relativehumidity_2m: [Double]
  let aerosol_optical_depth: [Double]
}
🚧 Known Issues & Gotchas
Hourly forecast only returns for next 2 days; beyond that, you only get daily aggregates.

Our score formula is simplistic: average of the three cloud‐cover layers at sunset. We ignore humidity/AOD for the next days.

The clamped(to:) helper must be declared internal (not package), or you’ll get “inaccessible due to package protection” errors.

Make sure your JSON keys (e.g. cloudCoverHigh) match your Swift property names exactly.

📋 Next Milestones
Polish Home & Detail UI

Restore the frosted “Today’s Conditions” grid on LocationDetailView

Add 10-day chart on detail too

Improve Score Formula

Factor in humidity, AOD for today; fall back gracefully for future days

Caching & Debounce

Throttle Open-Meteo calls to ≤1 per minute per location

Cache last‐fetched ForecastResponse for 10 minutes

App Store Prep

Add onboarding screen explaining “sunset score”

Build App Icon + Screenshots + Privacy description

Monetization

In‐app purchase to unlock more variables or custom alerts


Data Sources & Endpoints
Open-Meteo Forecast API (/v1/forecast)

Daily block (for the next 10 days):

time (ISO dates) → labels on the 10-day chart

sunset (ISO datetimes) → today’s sunset time & golden-hour start

cloudcover_mean (0–100) → fallback score for days 1–9

Hourly block (only covers the next ~48 hours):

time (ISO datetimes) → find the hour matching today’s sunset

cloudcover_high, cloudcover_mid, cloudcover_low (%) → feed into today’s score

relativehumidity_2m (%) → shown in “Today’s Conditions” grid

Open-Meteo Air-Quality API (/v1/air-quality)

Hourly block (next 24 hours):

aerosol_optical_depth → shown in “Today’s Conditions” grid

CoreLocation + CLGeocoder

Raw lat/lon → human-readable city, state, country for headers

Time zone identifier → format “local time” in favorites & search

📲 Mapping Data → UI
1. Home Screen (ContentView)
UI Element	Data Field(s)
“My Location” header	reverse-geocoded placemark.locality,administrativeArea,country
Score %	forecasts[0].score
Golden HH:MM	sunset[0] parsed as Date minus 30 minutes
Sunset HH:MM	sunset[0] parsed as Date
Clouds tile	cloudcover_mean[0] → label (“Clear”/“Partly”/“Overcast”)
High Clouds tile	cloudcover_high[idx0] → label (“None”/“Few”/“Many”)
Humidity tile	relativehumidity_2m[idx0] → label (“Dry”/“OK”/“Humid”)
AOD tile	aerosol_optical_depth[idx0] → label (“Low”/“Mod”/“High”)
10-Day Chart	time[i] + score[i] for i in 0..<10

where idx0 = index into hourly.time that matches the hour portion of daily.sunset[0].

2. Favorites List (FavoritesView)
Each row shows:

Name → Location.displayName

Local time “now” → Date() formatted with loc.timeZone

Today’s score → re-run the same formula as Home for that city

Tapping a row pushes the full detail view (which eventually mirrors Home for that location).

3. Search Modal (SearchView)
TextField → binds to SearchViewModel.searchText

Suggestions → [Location] returned by OpenMeteoSearchService.search(query)

Local “now” time beside each suggestion → same DateFormatter + loc.timeZone

4. Detail Screen (LocationDetailView)
(Work in progress—goal is to replicate Home but for any tapped/favorited location.)

🧮 The “Sunset Score” Formula
Today (day 0):

Find the hour of today’s sunset (idx0).

Take the average of the three cloud layers at that hour:

ini
Copy
Edit
raw = (cloud_high[idx0] + cloud_mid[idx0] + cloud_low[idx0]) / 3.0
score0 = clamp(Int(raw), 0...100)
(Later: could also factor humidity & AOD into score0, but for MVP we keep it simple.)

Future days (days 1–9):

Use the daily mean cloud cover as a proxy for overall cloudiness:

ini
Copy
Edit
score_i = max(0, 100 − Int(daily.cloudcover_mean[i]))
(i.e. clear days → higher score.)

🔑 Why These Choices?
Hourly vs. Daily: we only get reliable hourly layers for the next ~48 hours; after that, the API returns only daily aggregates.

Cloud layers at sunset: clouds are the single biggest driver of color scattering at that moment.

Mean daily cloud cover: a quick heuristic for multi-day forecasts.

Simplicity: keeps the score easy to understand & debug; we can layer on humidity/AOD later.