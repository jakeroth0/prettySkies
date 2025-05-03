# ContentView.swift

## Overview
The ContentView is the main view of the SunsetForecast app, displaying weather and sunset information for the user's current location. It shows a daily forecast, current conditions, and a 10-day forecast with sunset scores.

## Key Components

### State & Services
- `LocationManager`: Manages user location
- `SunsetService`: Handles weather and sunset data fetching
- Various state variables for location name, forecasts, and weather conditions

### UI Components

#### Background
- Gradient background using colors: #FF6B5C, #FFB35C, #FFD56B

#### Main Sections
1. **Header**
   - Displays "My Location" and the current location name

2. **Today's Score**
   - Shows percentage score
   - Displays golden hour and sunset times

3. **Today's Conditions**
   - Grid layout showing:
     - Cloud mean
     - Cloud at sun
     - AOD (Aerosol Optical Depth)

4. **10-Day Forecast**
   - Calendar-style view
   - Daily scores with visual progress bars
   - Weekday labels and percentage scores

### Data Management

#### Location Handling
- Automatically requests location on appear
- Updates when location changes
- Fetches location name using reverse geocoding

#### Weather Data
- Fetches weather and cloud cover data
- Processes daily and hourly forecasts
- Calculates sunset scores

## Helper Functions

### Variable Labels
- `labelCloudMean`: Formats cloud mean values
- `labelAOD`: Formats AOD values

### Data Processing
- `indexFor`: Finds index in hourly data for sunset time
- `fetchLocationName`: Gets location name from coordinates
- `loadData`: Fetches and processes weather data

## Error Handling
- Loading state indicator
- Error message display
- Graceful fallbacks for missing data 