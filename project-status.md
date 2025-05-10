# PrettySkies Project Status

## Project Overview

PrettySkies is an iOS app for forecasting sunset quality based on weather conditions and air quality data. The app uses data from various APIs to calculate scores for sunset viewing potential.

## Project Structure

### Directory Structure

```
SunsetForecast/
├── Assets.xcassets - App icons and images
├── Helpers/ - Utility classes and extensions
├── Location/ - Location management functionality
├── Models/ - Data structures and response models
├── Services/ - API integrations and data services
├── ViewModels/ - Business logic between Models and Views
└── Views/ - SwiftUI interface components
    └── Components/ - Reusable UI components
```

### Key Files and Relationships

#### App Foundation

- **SunsetForecastApp.swift**: Entry point for the app, initializes environment objects:
  - `FavoritesStore.shared` - Manages favorite locations
  - `LocationManager.shared` - Handles location services

#### Models

- **Location.swift**: Core data model representing a geographic location
  - Used throughout the app as the fundamental data unit
  - Properties: id, name, latitude, longitude, country, admin1, timeZoneIdentifier

- **ForecastResponse.swift**: Model for weather API responses
  - Contains nested structures for daily and hourly forecasts
  - Used by SunsetService to parse API responses

- **AQResponse.swift**: Model for air quality API responses
  - Used by AirQualityService to parse API responses

- **DailyForecast.swift**: Simplified model for displaying forecast data
  - Properties: id (Date), weekday (String), score (Int)
  - Used in forecast lists and cards

#### Services

- **SunsetService.swift**: Fetches weather data and calculates sunset quality
  - Primary data source for forecast information
  - Shared singleton instance used across the app

- **AirQualityService.swift**: Fetches air quality data for sunset clarity
  - Complements SunsetService with air quality metrics
  - Provides AOD (Aerosol Optical Depth) calculations

- **FavoritesStore.swift**: Manages saved favorite locations
  - Persists data using UserDefaults
  - Published properties to update UI when favorites change

- **LocationSearchService.swift**: Protocol for location search functionality
  - Implemented by OpenMeteoSearchService

- **OpenMeteoSearchService.swift**: Implementation for searching locations
  - Uses OpenMeteo GeoAPI to find locations by name

#### Location

- **LocationManager.swift**: Manages Core Location functionality
  - Handles location permissions and current user location
  - Shared singleton instance used across the app

#### ViewModels

- **SearchViewModel.swift**: Handles location search functionality
  - Converts user input into location search calls
  - Manages search results and UI state

- **TabViewSelection.swift**: Manages tab state across the app
  - Tracks selected tab and home page index
  - Allows coordinating UI across different views

#### Views

- **HomeView.swift**: Main view showing current location forecast
  - Features TabView for swiping between current and favorite locations
  - Shows overall sunset score and detailed conditions

- **FavoritesView.swift**: View for managing favorite locations
  - Features search functionality for adding new locations
  - Shows list of saved favorite locations with scores

- **LocationDetailView.swift**: Detailed view for a specific location
  - Shows comprehensive forecast information
  - Used when navigating to a specific favorite

- **LocationPreview.swift**: Preview for search results
  - Similar to LocationDetail but with "Add" button
  - Used when viewing search results

- **ContentView.swift**: DEPRECATED view, replaced by HomeView

- **Components/**: Reusable UI components
  - **ForecastCard.swift**: 10-day forecast display
  - **TodayConditionsCard.swift**: Today's detailed conditions
  - **GradientBackground.swift**: Dynamic gradient based on sunset score

#### Helpers

- **Color+Hex.swift**: Extension for creating Colors from hex strings
  - Used throughout the app for consistent color usage

- **Comparable+Clamp.swift**: Extension for clamping values to a range
  - Used in score calculations

- **GradientHelper.swift**: Helper for generating gradients based on scores
  - Used by GradientBackground

- **Environment.swift**: Environment helpers for UI adjustments

## Key Data Flows

1. **Location Flow**:
   - LocationManager gets device location
   - Geocoder translates coordinates to place name
   - HomeView uses coordinates to fetch forecast

2. **Forecast Flow**:
   - SunsetService fetches weather data using location coordinates
   - AirQualityService fetches air quality data
   - Data is processed into a sunset quality score
   - HomeView/ForecastCard display the processed data

3. **Favorites Flow**:
   - User searches for location using SearchViewModel
   - User adds location to FavoritesStore
   - FavoritesView displays saved locations
   - Selecting a favorite shows detailed forecast

## Dependency Management

- The app follows a singleton pattern for service classes:
  - LocationManager.shared
  - SunsetService.shared
  - AirQualityService.shared
  - FavoritesStore.shared

- Views receive dependencies through:
  - @EnvironmentObject for shared stores
  - Direct property injection for view-specific dependencies

## Bloat Reduction Opportunities

### Code Duplication

1. **Sunset Score Calculation Logic** appears in multiple places:
   - HomeView.swift
   - LocationDetailView.swift
   - FavoritesView.swift (FavRow)
   - LocationPreview.swift
   - **Solution**: Extract to a dedicated SunsetScoreCalculator class

2. **Date/Time Formatting** logic is duplicated:
   - **Solution**: Create a DateFormatter helper class

3. **Forecast Data Loading** appears in multiple places:
   - **Solution**: Create a unified ForecastLoader that handles both weather and air quality

### Unused Code

1. **ContentView.swift** is marked as deprecated:
   - **Solution**: Remove this file completely

2. **Duplicate UI Components** between LocationDetailView and LocationPreview:
   - **Solution**: Create a shared BaseLocationView they can both use

### Architecture Improvements

1. **Singleton Management**:
   - Current approach uses many singletons, which can complicate testing
   - **Solution**: Consider a proper dependency injection system

2. **Error Handling**:
   - Current approach has inconsistent error handling
   - **Solution**: Implement a unified ErrorHandler system

3. **Offline Support**:
   - App currently has no offline capabilities
   - **Solution**: Implement proper caching and offline mode

4. **SwiftUI Previews**:
   - Some previews use direct constructor initialization while others use singletons
   - **Solution**: Standardize preview approach for consistency

5. **View Structure**:
   - Some views are quite large and do multiple things
   - **Solution**: Break down large views into more focused components

## Recommended Next Steps

1. **Refactor Score Calculation**:
   - Create a dedicated SunsetScoreService
   - Move all score calculation logic to this service
   - Use consistently across all views

2. **Standardize Data Loading**:
   - Create a unified ForecastRepository that abstracts data sources
   - Implement proper caching mechanism
   - Add error handling and retry logic

3. **Clean Up View Hierarchy**:
   - Extract repeated UI elements into reusable components
   - Establish consistent patterns for view construction

4. **Documentation**:
   - Add comprehensive documentation to all public APIs
   - Document key algorithms like score calculation

5. **Testing**:
   - Add unit tests for core business logic
   - Add UI tests for critical user flows

## Future Feature Considerations

1. **Widgets**: Home screen widgets showing sunset forecast
2. **Notifications**: Alert users about high-quality sunset opportunities
3. **Photo Sharing**: Allow users to share sunset photos within the app
4. **Advanced Filtering**: Filter favorites by score, time zone, etc.
5. **Historical Data**: Track sunset quality over time 

## Complete File Listing

### Root Directory Files
- README.md - Basic project overview and setup instructions
- project-status.md - Comprehensive project status documentation
- taskList.md - List of project tasks and status
- rules-v1.md - Coding guidelines and rules
- contextForProject.md - Project context information
- ContentView.md, FavoritesView.md - Documentation for specific views
- PROJECT_STRUCTURE.md - Project structure overview
- .gitignore - Git exclusion list
- SanFrancisco.gpx - GPX file for location simulation in Xcode

### App Directory (SunsetForecast/)

#### Core App Files
- SunsetForecastApp.swift - App entry point that initializes environment objects
- Info.plist - App configuration file

#### Models Directory (SunsetForecast/Models/)
- Location.swift - Core data model for geographic locations
- ForecastResponse.swift - Model for parsing weather API responses
- AQResponse.swift - Model for parsing air quality API responses
- DailyForecast.swift - Simplified model for displaying forecast data

#### Services Directory (SunsetForecast/Services/)
- SunsetService.swift - Fetches weather data and calculates sunset quality
- AirQualityService.swift - Fetches air quality data for sunset clarity
- FavoritesStore.swift - Manages saved favorite locations
- LocationSearchService.swift - Protocol for location search functionality
- OpenMeteoSearchService.swift - Implementation for searching locations

#### ViewModels Directory (SunsetForecast/ViewModels/)
- SearchViewModel.swift - Handles location search functionality

#### Views Directory (SunsetForecast/Views/)
- HomeView.swift - Main view showing current location forecast
- FavoritesView.swift - View for managing favorite locations
- LocationDetailView.swift - Detailed view for a specific location
- LocationPreview.swift - Preview for search results
- ContentView.swift - Deprecated view, replaced by HomeView
- FullscreenFavoritesView.swift - Full screen view for favorites
- HomeFavoritesView.swift - Home view for favorites
- BottomNavBar.swift - Navigation bar component
- SearchResultRow.swift - Component for displaying search results

#### Views/Components Directory (SunsetForecast/Views/Components/)
- ForecastCard.swift - 10-day forecast display component
- TodayConditionsCard.swift - Today's detailed conditions component
- GradientBackground.swift - Dynamic gradient background based on sunset score

#### Helpers Directory (SunsetForecast/Helpers/)
- GradientHelper.swift - Helper for generating gradients based on scores
- Environment.swift - Environment helpers for UI adjustments
- Color+Hex.swift - Extension for creating Colors from hex strings
- Comparable+Clamp.swift - Extension for clamping values to a range

#### Location Directory (SunsetForecast/Location/)
- LocationManager.swift - Manages Core Location functionality

### Test Directory (SunsetForecastTests/)
- GradientHelperTests.swift - Unit tests for GradientHelper

### Xcode Project Files (SunsetForecast.xcodeproj/)
- project.pbxproj - Xcode project configuration file

### Recently Deleted Files
- SunsetForecast/Models/SearchLocationPreview.swift
- SunsetForecast/Services/ForecastStore.swift
- SunsetForecast/Services/LocationManager.swift (Note: A file with the same name exists in the Location directory) 