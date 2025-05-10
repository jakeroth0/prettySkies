# Taskmaster

_A living checklist of features, their status, and the next steps._

---

## 🎯 Overall Goal  
Build a beautiful sunset-forecast app with:
- A dynamic, multi-stop gradient home screen and cards  
- Real-time "sunset score," golden hour & sunset times  
- Detailed "Today's Conditions" and 10-day forecast cards  
- Full-screen search & favorites management  

---

## ✅ Completed Core Features

1. **Gradient Home Screen**  
   - Static two-color gradient background  
2. **Current Location Fetch**  
   - CoreLocation + reverse geocoding → city name  
3. **Sunset Score Calculation**  
   - Today's score: average of hourly high/mid/low cloudcover  
   - 10-day scores: inverse of daily mean cloudcover  
4. **Golden Hour / Sunset Times**  
   - Computed "Golden" (–30 min) and "Sunset" times  
5. **Today's Variables Card**  
   - Frosted-glass card showing Clouds / High-Cloud / Humidity / AOD  
6. **10-Day Forecast Card**  
   - Frosted-glass list of abbreviated weekdays + score bars  

---

## ✅ Completed "Favorites" & Search

1. **Full-screen Search UI**  
2. **Favorites List UI** (black background, "Sunsets" title, cards)  
3. **Tap-through to LocationDetailView**  
4. **Favorites Cards**: Local "now" time + sunset score  

---

## ✅ Completed Miscellaneous

- **Multi-location Swipe** on home screen  
- **Basic error/loading states** and console logging  

---

## 🛠️ Layout Consistency Fixes

1. [x] **Create Debug Visualization Helpers**
   - ✅ Added visual overlays to identify safe areas
   - ✅ Added logging of insets and geometry for troubleshooting
   - ✅ Created toggle to enable/disable debug helpers

2. [x] **Normalize ContentView Layout Pattern**
   - ✅ Documented what makes ContentView layout work correctly
   - ✅ Extracted consistent layout pattern with appropriate spacing
   - ✅ Verified that this pattern handles Dynamic Island and notches properly

3. [x] **Fix FavoriteLocationView Layout**
   - ✅ Applied ContentView pattern to fix content positioned too low
   - ✅ Ensured consistent spacing with header and safe areas
   - ✅ Tested across different device sizes

4. [ ] **Fix FullscreenFavoritesView Layout**
   - Apply ContentView pattern to fix content positioned too high
   - Adjust header positioning and safe area handling
   - Verify content doesn't overlap status bar or Dynamic Island

5. [ ] **Fix LocationPreview Layout**
   - Remove gray bar at top by fixing safe area handling
   - Apply consistent content padding to match other views
   - Maintain Cancel/Add buttons properly positioned

6. [ ] **Create Reusable Layout Component (Optional)**
   - Evaluate benefits of a shared LocationContentView component
   - Extract common layout structure if beneficial
   - Enable customization for different header styles (Back, Cancel/Add)

7. [ ] **Document Layout Best Practices**
   - Add comments in key files explaining the layout approach
   - Create a brief layout guideline document for future reference

---

## ⏳ Remaining / Next-Phase Tasks

1. [ ] **Dynamic Gradient Colouring**  
   - Switch from static two-color to three-stop gradient depending on score  
2. [ ] **Remember Last-Viewed**  
   - On launch, default to current location (not a stale favorite)  
3. [ ] **UI Polish**  
   - Apply dynamic gradients to Favorites cards  
   - Add plenty of in-code comments & console logs for debuggability  
4. [ ] **App Store Prep**  
   - Icons, provisioning, promo screenshots, TestFlight setup  
5. [ ] **Paywall / In-App Purchase**  
   - Lock premium features behind paywall or one-time purchase  
6. [ ] **Refactor & Clean-up**  
   - Simplify codebase, remove redundancies, enforce styling guidelines  

---

## 🚀 Recommended Next Step

1. **Implement Dynamic Gradient**  
   - Define three color stops per score band  
   - Plug into `LinearGradient` on home & card views  
   - Verify visually against sample palettes  

After that, we can tackle "Remember Last-Viewed" logic, then move on to UI polish and finally App Store & IAP preparation.

---

