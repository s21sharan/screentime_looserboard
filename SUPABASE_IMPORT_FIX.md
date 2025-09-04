# Fix Supabase Import Error

## Steps to resolve "no such module 'Supabase'" error:

### 1. Add Supabase Package to Your Target

1. Open your project in Xcode
2. Select your project in the navigator (top blue icon)
3. Select your app target (screentime_lboard)
4. Go to the "General" tab
5. Scroll down to "Frameworks, Libraries, and Embedded Content"
6. Click the "+" button
7. Select "Supabase" from the list
8. Make sure it's set to "Do Not Embed"

### 2. Alternative: Re-add the Package

If the above doesn't work:

1. Go to File → Add Package Dependencies
2. Remove the existing Supabase package if present
3. Add it again with URL: `https://github.com/supabase-community/supabase-swift`
4. Click "Add Package"
5. Select these products for your target:
   - Supabase
   - Auth (if available separately)
   - Realtime (if available separately)
6. Click "Add Package"

### 3. Clean and Rebuild

1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)

### 4. Check Build Settings

1. Select your target
2. Go to "Build Settings" tab
3. Search for "Framework Search Paths"
4. Make sure it includes `$(inherited)`

### 5. Update Package Versions

If still having issues:
1. Right-click on the package in the project navigator
2. Select "Update to Latest Package Versions"

### 6. Manual Import Path (Last Resort)

In Build Settings:
1. Search for "Import Paths"
2. Add: `${BUILD_DIR}/GeneratedModuleMaps`