# PrettySkies Project Structure

## Root Directory (`/`)
```
prettySkies/
├── .git/                    # Git version control
├── .gitignore              # Git ignore rules
├── .venv/                  # Python virtual environment
├── README.md               # Project documentation
├── SanFrancisco.gpx        # Location data for testing
├── sunsetResearch.md       # Research notes
├── Untitled.ipynb          # Jupyter notebook
└── SunsetForecast/         # Main iOS app directory
```

## iOS App Directory (`/SunsetForecast`)
```
SunsetForecast/
├── Assets/                 # Additional assets
├── Assets.xcassets/        # Xcode asset catalog
├── Info.plist             # App configuration
├── Location/              # Location services
├── Models/                # Data models
├── Services/              # API and business logic
├── Views/                 # SwiftUI views
└── SunsetForecastApp.swift # App entry point
```

## Key Components

### Location (`/SunsetForecast/Location`)
- `LocationManager.swift`: Handles user location services and permissions
- Manages CoreLocation integration for sunset predictions

### Services (`/SunsetForecast/Services`)
- `SunsetService.swift`: Manages API calls to Open-Meteo
- Handles sunset time and weather data fetching
- Includes mock service for testing

### Views (`/SunsetForecast/Views`)
- `ContentView.swift`: Main app view
- Displays sunset times and weather information
- Manages user interface and state

### Models (`/SunsetForecast/Models`)
- Data structures for API responses
- Business logic models

### Assets
- `Assets.xcassets/`: Xcode asset catalog for images and colors
- `Assets/`: Additional resources

## Development Tools
- `.venv/`: Python virtual environment for development tools
- `.ipynb_checkpoints/`: Jupyter notebook checkpoints
- `.eslintrc.cjs`: ESLint configuration for code quality

## Project Configuration
- `SunsetForecast.xcodeproj/`: Xcode project configuration
- `Info.plist`: iOS app configuration and permissions
- `README.md`: Project documentation and setup instructions 