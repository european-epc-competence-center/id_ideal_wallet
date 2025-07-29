# AI Notes - Persistent Memory

## Current Session - 2024-12-19

**Status:**
- ✅ Completed: Notes structure reorganization and setup
- ✅ Completed: ID Card flow technical analysis
- ✅ Completed: eID flow standardization and code quality improvements
- ✅ Completed: Fixed automatic screen skipping and enhanced information display
- ✅ Completed: Comprehensive eID flow analysis and documentation
- ✅ Completed: Home and Wallet screen merge - removed home screen, made wallet default
- ✅ Completed: Added "Wallet" header to top left of credential page
- ✅ Completed: Added settings icon to wallet page top right and removed from bottom navigation
- ✅ Completed: Fixed settings page black background issue and added close button
- ✅ Completed: Fixed bottom navigation spacing to make ID Card button symmetric with Wallet button

**Latest Task - Bottom Navigation Spacing Fix:**

**Problem Identified:**
- ID Card button had inconsistent spacing to QR FAB compared to Wallet button
- Left side (Wallet) used `Spacer(flex: 2)` creating flexible space
- Right side (ID Card) used fixed `SizedBox(width: 20)` creating asymmetric layout

**What was done:**
1. **Made Spacing Symmetric**: Changed right side to mirror left side spacing pattern
2. **Used Consistent Spacers**: Replaced `SizedBox(width: 20)` with `Spacer(flex: 2)` and `Spacer()`
3. **Updated Alignment**: Changed from `MainAxisAlignment.spaceAround` to `MainAxisAlignment.end`
4. **Perfect Symmetry**: Now both sides have identical spacing patterns around the QR FAB

**Technical Changes:**
- `main.dart`: Right side now uses `Spacer(flex: 2)` + button + `Spacer()` pattern
- Matches left side: `Spacer()` + button + `Spacer(flex: 2)` pattern
- Creates balanced visual spacing on both sides of the floating action button

**Previous Task - Settings Page Background Fix:**

**Problem Identified:**
- Settings page showed black/transparent background when opened via navigateClassic()
- Root cause: StyledScaffoldTitle uses `backgroundColor: Colors.transparent` which works embedded but fails standalone
- Missing close button for proper navigation back

**What was done:**
1. **Replaced StyledScaffoldTitle**: Changed SettingsPage to use standard Scaffold instead of StyledScaffoldTitle
2. **Added Close Button**: Added X (close) button in top left of AppBar following AusweisView pattern
3. **Fixed Background**: Removed transparent background, now uses default Material Design background
4. **Maintained Layout**: Preserved same margin and structure as before
5. **Consistent Navigation**: Follows same pattern as other full-screen views (AusweisView, WebView)

**Technical Changes:**
- `SettingsPage.dart`: Replaced StyledScaffoldTitle with Scaffold + AppBar + SafeArea
- Added IconButton with Icons.close in AppBar leading position
- Removed StyledScaffoldTitle import
- Used same Container margin (left: 10, right: 10, top: 0) for consistency
- Title styling matches other full-screen views

**Previous Task - Settings Icon to Wallet Header:**

**What was done:**
1. **Added Settings Icon**: Added settings icon to wallet page app bar actions (top right)
2. **Removed Bottom Navigation**: Removed settings option from bottom navigation bar entirely
3. **Updated Navigation Logic**: Removed NavigationPage.settings case from main switch statement
4. **Preserved Sub-Navigation**: Kept license and searchNewAbo navigation cases for internal settings navigation
5. **Full-Screen Navigation**: Settings now opens as a new full-screen view using navigateClassic()

**Technical Changes:**
- `CredentialPage.dart`: Added settings icon to appBarActions using navigateClassic(SettingsPage())
- `main.dart`: Removed CustomNavigationItem for settings from bottom bar
- `main.dart`: Removed NavigationPage.settings case from getContent() switch
- Settings icon always visible, QR code icon conditional on ISO mDoc credentials
- Used same navigation pattern as other full-screen views (ID card, etc.)

**Previous Task - Wallet Header Addition:**

**What was done:**
1. **Modified StyledScaffoldTitle**: Added `leftTitle` parameter to support left-aligned titles
2. **Updated AppBar Layout**: When `leftTitle` is provided, creates a Row with title on left and widgets on right
3. **Updated CredentialPage**: Added `leftTitle: "Wallet"` to display "Wallet" header on top left
4. **Preserved Functionality**: Dropdown menu still works and appears on the right side of the app bar

**Technical Changes:**
- `StyledScaffoldTitle.dart`: Added `leftTitle` parameter and conditional layout logic
- `CredentialPage.dart`: Added `leftTitle: "Wallet"` parameter to show header
- Layout uses Row with Spacer to position "Wallet" on left and dropdown on right
- Maintains responsive design and existing styling

**Previous Task - Home/Wallet Screen Merge:**

**What was done:**
1. **Removed Home Screen**: Changed default page from `NavigationPage.abo` to `NavigationPage.credential`
2. **Updated Navigation**: Removed `abo` case from navigation switch, made wallet the default content
3. **Cleaned Up References**: Updated all references from `abo` to `credential` in navigation providers
4. **Removed Unused Code**: Deleted unused enum values (`abo`, `aboDetail`) and import statements
5. **Centered Wallet Tab**: Updated bottom navigation layout to center the Wallet tab on the left side

**Navigation Structure Now:**
- **Left:** Wallet tab (centered) - navigates to CredentialPage
- **Center:** QR Scanner FAB (floating action button)
- **Right:** ID Card + Settings tabs

**Technical Changes:**
- `NavigationProvider.activeIndex` default changed from `abo` to `credential`
- Removed `NavigationPage.abo` and `NavigationPage.aboDetail` from enum
- Updated `getContent()` switch statement to remove abo case
- Updated back navigation logic to use `credential` instead of `abo`
- Centered Wallet tab using `MainAxisAlignment.center` instead of `spaceAround`
- Removed unnecessary `SizedBox` spacing in left navigation area

**eID Flow Analysis - Complete Technical Overview:**

**Architecture Overview:**
- Uses AusweisApp2 SDK (German federal eID solution) integrated via native Android/iOS bridge
- Flutter app communicates with native AusweisApp2 service via MethodChannel/EventChannel
- Two main flows: Self-initiated credential creation and External authentication requests
- Certificate validation uses hardcoded root certificates in `root_certificates.dart`

**eID Flow Components:**
1. **Native Integration**: AusweisApp2 SDK handles actual eID communication and NFC operations
2. **Flutter Bridge**: `AusweisProvider` manages state and communicates with native layer
3. **UI Flow**: Series of screens (start → NFC → PIN → completion) managed by `AusweisView`
4. **Certificate Handling**: X.509 certificates validated against embedded root CAs
5. **Data Processing**: Personal data extracted and processed for credential issuance

**Deep Link Trigger:**
- `eid://` URLs trigger external authentication flow
- Contains `tcTokenURL` parameter pointing to service provider
- Handled in `NavigationProvider.handleLink()` around line 130-139

**Certificate Management:**
- Root certificates hardcoded in `lib/constants/root_certificates.dart`
- Contains CA certificates for Hochschule Mittweida (development/testing environment)
- Apple certificates for PKPass validation
- Certificate validation happens in native AusweisApp2 SDK

**Key Technical Details:**
- NFC communication handled entirely by AusweisApp2 SDK
- PIN verification, CAN/PUK handling managed by SDK
- Data extraction returns structured personal information
- Age verification backend integration at `https://eatfresh.ssi.eecc.de/verify-age`

**Findings:**
- Project had only structure.md in notes folder, missing required index.md and ai-notes.md
- Workspace rules define clear requirements for notes organization and AI memory persistence
- Structure.md contains comprehensive project overview (10KB, 281 lines)

**ID Card Flow Analysis:**
- Current flow: HomeScreen → ID Card nav button → AusweisStart → automatically navigates to AusweisView
- AusweisStart serves as unnecessary intermediate layer that immediately redirects
- Navigation uses both NavigationProvider (for main app nav) and direct Navigator.push (for ID card flow)
- Flow is technically sound but has architectural inconsistencies
- State management through AusweisProvider with EventChannel/MethodChannel communication to native AusweisApp2 SDK

**Technical Architecture Issues Found:**
1. **Mixed Navigation Patterns**: Uses both provider-based navigation and direct Navigator.push
2. **Redundant Screen**: AusweisStart exists only to immediately navigate to AusweisView
3. **Inconsistent State Management**: ID card flow doesn't follow the same navigation patterns as rest of app
4. **Deep Linking**: Handles 'eid://' URLs separately from main navigation flow

**Solution Implemented:**
1. **Removed AusweisStart**: Deleted redundant intermediate screen entirely
2. **Updated Navigation**: Changed bottom nav to route directly to `NavigationPage.ausweis`
3. **Added Home Button**: Added dedicated ID card button to home screen grid
4. **Standardized Navigation**: Both home button and bottom nav now use `navigateClassic()` for consistent full-screen experience
5. **Fixed Navigation Logic**: CustomNavigationItem now handles ausweis specially to open new view instead of changing page content
6. **Fixed Automatic Skipping**: Removed automatic `startProgress()` call from `initState()`
7. **Enhanced Start Screen**: Added informative display showing what will happen next
8. **Context-Aware Information**: Different content for self-initiated vs external requests

**Information Display Enhancement:**
- **Process Overview**: Shows step-by-step what will happen (NFC, security, PIN, etc.)
- **Context Awareness**: Different content for `selfInfo` (credential creation) vs external requests
- **Visual Improvements**: Icons, cards, better typography, and color coding
- **External Request Indicator**: Special warning when triggered by deep link
- **Clear Call-to-Action**: Button text adapts to context (credential conversion vs authentication)

**Technical Improvements:**
- **Separated Concerns**: `startProgress()` for immediate start, `setupExternalRequest()` for context setup
- **Consistent Deep Link Handling**: Both `eid://` and OIDC flows now show information screen first
- **Better UX**: User always sees what will happen before proceeding

**Key Technical Difference Discovered:**
- `navigateClassic()`: Uses Navigator.push() → Opens new full-screen view (desired behavior)
- `changePage()`: Changes content within existing scaffold → Keeps bottom nav visible (undesired for ID card)

**Decisions:**
- Created index.md as main navigation hub referencing existing structure.md
- Established ai-notes.md for persistent session memory
- Maintained existing structure.md as detailed reference document
- Removed AusweisStart completely while preserving all functionality
- Used special case handling in CustomNavigationItem for consistent UX

**Next Steps:**
1. ✅ All eID flow improvements completed
2. Monitor for any issues with the new navigation pattern
3. Consider applying similar patterns to other full-screen flows if needed

**Open Questions:**
- ✅ Resolved: AusweisStart removed entirely
- ✅ Resolved: Navigation patterns unified with special case handling
- ✅ Resolved: Both access methods now work identically

**Key Files Modified:**
- `[main.dart](mdc:lib/main.dart)` - Updated navigation routing, removed AusweisStart import
- `[navigation_pages.dart](mdc:lib/constants/navigation_pages.dart)` - Removed ausweisStart enum
- `[abo_overview.dart](mdc:lib/views/abo_overview.dart)` - Added ID card button to home screen
- `[custom_navigation_item.dart](mdc:lib/basicUi/standard/custom_navigation_item.dart)` - Special case for ausweis navigation
- `[ausweis_start.dart](mdc:lib/views/ausweis_start.dart)` - **DELETED** (redundant file removed)

**Key Files Referenced:**
- `[index.md](mdc:.cursor/notes/index.md)` - Main notes navigation
- `[structure.md](mdc:.cursor/notes/structure.md)` - Detailed project structure
- `[notes-unified.mdc](mdc:.cursor/rules/notes-unified.mdc)` - Unified notes management rules
- `[ausweis_view.dart](mdc:lib/views/ausweis_view.dart)` - Main ID card interface
- `[ausweis_provider.dart](mdc:lib/provider/ausweis_provider.dart)` - ID card state management
- `[navigation_provider.dart](mdc:lib/provider/navigation_provider.dart)` - Main app navigation

## Previous Sessions

*No previous sessions recorded yet* 