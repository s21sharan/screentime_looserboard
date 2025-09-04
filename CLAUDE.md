# CLAUDE.md - Project Memory

## 2025-09-04 – Compact Session

#CurrentFocus
Successfully integrated Supabase authentication using individual module imports to resolve import issues

#SessionChanges
• Fixed "No such module 'Supabase'" by using individual imports (Auth, Realtime, PostgREST)
• Updated AuthManager to use Auth module directly with KeychainLocalStorage
• Modified SupabaseClient to use individual module imports instead of unified import
• Added proper localStorage parameter to AuthClient initialization
• Fixed async/await warning in setupAuthListener method
• Created AuthTest.swift for testing authentication flow
• Build succeeded with new import structure

#NextSteps
• Test sign up and login flow with Supabase backend
• Implement actual leaderboard data fetching from Supabase
• Remove AuthTest.swift and restore normal app flow
• Connect groups and screen time data to UI

#BugsAndTheories
• No such module 'Supabase' ⇒ Main module unavailable, use individual imports
• nil localStorage error ⇒ AuthClient requires KeychainLocalStorage implementation

#Background
• App rebranded to "ScreensAway" with bold, serious styling
• Using username-based auth that converts to email format for Supabase
• SQL schema includes profiles, groups, and screen time entries with RLS