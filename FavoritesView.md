# FavoritesView.swift

## Overview
The FavoritesView displays a list of saved favorite locations and their current sunset scores. It includes the user's current location and allows navigation to location details and search functionality.

## Key Components

### State & Services
- `FavoritesStore`: Environment object for managing favorite locations
- `LocationManager`: Manages user location
- `SunsetService`: Handles weather data fetching
- State variables for search and selection

### UI Components

#### Navigation
- NavigationStack for hierarchical navigation
- Sheet presentation for search functionality
- Navigation destination for location details

#### Main Sections
1. **Current Location Card**
   - Button to select current location
   - Uses `FavRow` component

2. **Header**
   - "Sunsets" title
   - Search button with magnifying glass icon

3. **Saved Favorites**
   - List of favorite locations
   - Each location uses `FavRow` component

### FavRow Component

#### Layout
- Location name and local time
- Sunset score percentage
- Ultra-thin material background
- Rounded corners

#### Functionality
- Updates local time based on location's timezone
- Fetches and displays sunset score
- Handles data fetching errors

## Data Management

### Location Handling
- Requests location on appear
- Creates current location object from coordinates
- Manages location selection state

### Weather Data
- Fetches cloud cover data for each location
- Calculates sunset scores
- Updates scores asynchronously

## Helper Functions

### Time Management
- `updateLocalTime`: Updates local time display
- `updateScore`: Fetches and updates sunset score

### Data Processing
- `indexFor`: Finds index in hourly data for sunset time
- `currentLocation`: Creates location object from current coordinates 