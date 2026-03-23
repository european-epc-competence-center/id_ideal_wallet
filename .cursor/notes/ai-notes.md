# AI Notes - Persistent Memory

## Session - 2026-03-23: dart_ssi API migration fixes

**Status:** ✅ Completed

**Problem:** After switching `dart_ssi` dependency to the EECC fork (commit 6fb33d), 15+ compile errors and runtime crashes.

**Compile Errors Fixed:**
1. `dart_ssi_compat.dart`: `pc.decodeBigIntWithSign`/`pc.encodeBigIntAsUnsigned` not in pointycastle 4.0 public API → added local `_decodeBigIntWithSign`/`_encodeBigIntAsUnsigned` helpers
2. `dart_ssi_compat.dart`: Added missing `json_path` import for `JsonPath`
3. `dart_ssi_compat.dart`: `FutureOr<bool>` return type from `_wallet.verify` → made method `async`/`await`
4. `dart_ssi_compat.dart`: `WalletKeyAgreementGenerator` now exported by dart_ssi → removed duplicate class, re-export from dart_ssi instead
5. `oidc_handler.dart`: `authorizationServer!.first` → `authorizationServer` is now `String?` not `List<String>?`; also check `authorizationServers` fallback
6. `oidc_handler.dart`: `proofTypesSupported?['jwt']?.cast<String>()` → use `.signingAlgValuesSupported.cast<String>()`
7. `oidc_handler.dart`: `SdJwt.verified(parsed, jwk)` removed → use `SdJwt.fromSdJws(parsed)` + `sd.verify()`
8. `oidc_handler.dart`+`mdoc_provider.dart`: `x509chain` changed from `List<int>` to `List<List<int>>` in iso_mdoc → use `.first`
9. `presentation_request.dart`: `sd.claims` → `sd.additionalClaims ?? {}`

**Runtime Errors Fixed:**
10. `oidc_handler.dart`: Old-format OID4VCI credential offers (missing `@context`) crash `OidCredentialOffer.fromUri` → added `_normaliseCredentialOffer()` pre-processor
11. `MainActivity.kt`+`ausweis_provider.dart`: `disconnectSdk` called multiple times causes `IllegalArgumentException` → guard with `boundToService` flag in Kotlin; make Dart method `async`/`await` so exception is caught

**Key Files Modified:**
- `lib/functions/dart_ssi_compat.dart`
- `lib/functions/oidc_handler.dart`
- `lib/provider/mdoc_provider.dart`
- `lib/provider/ausweis_provider.dart`
- `lib/views/presentation_request.dart`
- `android/app/src/main/kotlin/eu/hidy/app/MainActivity.kt`

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
- ✅ Completed: Fixed license navigation bug and settings page syntax error
- ✅ Completed: Inter font installation - replaced Outfit with Inter throughout the app
- ✅ Completed: Fixed credential deletion navigation to go to credential page like back arrow
- ✅ Completed: Changed wallet icon from co_present to account_balance_wallet in bottom navigation
- ✅ Completed: Modernized AusweisView start screen with clear eID reading and credential issuance info

**Latest Task - Wallet Icon Change:**
**Latest Task - Empty Credential Page Modernization:**

**What was done:**
1. **Modernized Empty State**: Replaced simple "No Credentials" text with informative, modern layout
2. **Added New Localization Strings**: Created emptyCredentialTitle, emptyCredentialEidInfo, emptyCredentialQrInfo in both German and English
3. **Informative Content**: Added clear descriptions about eID functionality and QR code scanning
4. **Modern Design**: Used clean layout with icons, proper spacing, and typography hierarchy
5. **User Guidance**: Explains both main app functions without buttons (as requested)

**Technical Changes:**
- `lib/l10n/app_de.arb`: Added 3 new German localization strings for empty state
- `lib/l10n/app_en.arb`: Added 3 new English localization strings for empty state  
- `lib/views/credential_page.dart`: Replaced Center/Text with Padding/Column layout including NFC and QR scanner icons with descriptions
- Used blue icons (Color(0xFF2563EB)) for visual consistency
- Maintained responsive design with Expanded widgets

**Design Details:**
- **Welcome Title**: "Willkommen in Ihrer digitalen Wallet" / "Welcome to your digital wallet"
- **eID Info**: Explains NFC reading of electronic ID card for credential creation
- **QR Info**: Explains QR code scanning for receiving/presenting credentials
- **Layout**: Centered column with 40px spacing, icon+text rows with 24px between sections
- **Typography**: 24px title (w600), 16px body text with 1.5 line height
- **Icons**: 32px NFC and QR scanner icons in blue theme color

**Impact:**
- Landing page now educates users about key app functionality
- Clean, modern appearance without being bloated
- Clear user expectations about eID reading and QR scanning capabilities
- No action buttons added (as requested) - information only

**Previous Task - AusweisView Modernization:**

**What was done:**
1. Updated the ID card (`AusweisView`) start screen to a more modern layout
2. Added explicit copy: we will read the eID (via NFC) and create two credentials – an ID Card credential and an age credential (16+ or 18+ based on actual age)
3. Introduced a "Sie erhalten" section and later enlarged it, stacking ID Card and Age credentials vertically for emphasis
4. Removed the "Ablauf" section per UX direction, simplifying the screen
5. Updated CTA button text for clearer action phrasing

**Technical Changes:**
- `lib/views/ausweis_view.dart`: Updated hero title/description, added "Sie erhalten" section, refined steps, updated CTA labels
- No changes to flow/state; only UI/copy updates

**Impact:**
- Clearer user expectations before starting NFC
- Explicitly communicates that ID Card and age credentials are issued from eID data
- More modern hierarchy and visuals without affecting business logic


**What was done:**
1. **Updated Wallet Icon**: Changed bottom navigation wallet icon from `Icons.co_present`/`co_present_outlined` to `Icons.account_balance_wallet`/`account_balance_wallet_outlined`
2. **Located Oval Border Styling**: Identified that the oval border around navigation icons is defined in `CustomNavigationItem` widget with `BorderRadius.circular(15)` and grey background colors

**Technical Changes:**
- `main.dart`: Updated CustomNavigationItem for wallet to use account_balance_wallet icons
- Oval border styling located in `lib/basicUi/standard/custom_navigation_item.dart` lines 34-44

**Previous Task - Credential Deletion Navigation Fix:**

**Problem Identified:**
- When deleting a credential from credential detail page, it used `goBack()` method
- This didn't consistently navigate to credential page like the back arrow button does
- Back arrow uses `changePage([NavigationPage.credential])` for direct navigation

**What was done:**
1. **Unified Navigation Behavior**: Changed credential deletion to use same navigation as back arrow
2. **Simplified Logic**: Removed conditional logic for different credential types
3. **Consistent UX**: Now both back arrow and delete actions lead to credential page

**Technical Changes:**
- `CredentialDetail.dart`: Changed from `goBack()` to `changePage([NavigationPage.credential])`
- Removed conditional navigation based on credential type
- Both navigation paths now behave identically

**Latest Task - Inter Font Installation:**

**What was done:**
1. **Font Files Copied**: Copied 9 Inter font weights from Downloads to `assets/fonts/Inter/`
   - Inter_18pt-Thin.ttf (weight: 100) through Inter_18pt-Black.ttf (weight: 900)
2. **pubspec.yaml Updated**: Added Inter font family configuration with proper weight mappings
3. **Dependencies Refreshed**: Ran `flutter clean` and `flutter pub get`
4. **Theme Updated**: Changed default font from 'Outfit' to 'Inter' in theme.dart
5. **Complete Font Replacement**: App now uses Inter font throughout instead of Outfit

**Technical Changes:**
- `pubspec.yaml`: Added Inter font family with 9 weight variants (100-900)
- `lib/basicUi/standard/theme.dart`: Changed `fontFamily: 'Outfit'` to `fontFamily: 'Inter'`
- `assets/fonts/Inter/`: Added 9 Inter font files for different weights

**Latest Task - License Navigation Bug Fix:**

**Problem Identified:**
- License option in settings couldn't be clicked - nothing happened
- When closing settings, it would then unexpectedly navigate to licenses (bugged behavior)
- Root cause: Syntax error in settings_page.dart and incorrect navigation method

**What was done:**
1. **Fixed Syntax Error**: Added missing `ListTile(` opening tag for backup section that was causing widget tree corruption
2. **Fixed License Navigation**: Changed from `changePage([NavigationPage.license])` to direct `navigateClassic(LicensePage(...))` 
3. **Proper Full-Screen Navigation**: License page now opens as full-screen view like other settings options
4. **Used Correct LicensePage Widget**: Directly instantiated Flutter's LicensePage with proper app info

**Technical Changes:**
- `SettingsPage.dart`: Fixed missing ListTile opening tag for backup section
- `SettingsPage.dart`: Changed license navigation to use `navigateClassic()` with actual LicensePage widget
- Added proper app metadata: 'EECC Identity Wallet', version from `versionNumber`, app icon
- Now follows same navigation pattern as other settings options (backup, etc.)

**Root Cause Analysis:**
- **Syntax Error**: Missing `ListTile(` tag corrupted the widget tree, breaking touch events
- **Wrong Navigation Method**: `changePage()` changes content within settings scaffold, but settings is a full-screen view
- **Navigation Conflict**: When settings closed, pending page change would execute, causing delayed navigation to licenses

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

## dart_ssi EECC Fork API Migration - 2026-03-23

**Status:** ✅ All migration tasks completed

**Summary of Changes:**
- Created `lib/functions/dart_ssi_compat.dart` as a compatibility shim re-implementing removed dart_ssi functions and providing adapter classes (`WalletCryptoProvider`, `WalletSignatureGenerator`, `WalletKeyAgreementGenerator`, `EdDsaSigner`, `JsonWebSignature2020Signer`)
- Updated all imports: `dart_ssi/oidc.dart` → `dart_ssi/oid.dart`, `dart_ssi/x509.dart` → `dart_ssi/util.dart`
- Renamed all `Oidc*` types to `Oid*` (e.g., `OidcCredentialOffer` → `OidCredentialOffer`)
- Migrated `Credential` field access: `w3cCredential` → `verifiableCredential`, `plaintextCredential` → `metadata`
- Fixed `WalletStore` call sites: named params for `openBoxes`, `initializeIssuer`, `getNextConnectionDID`, `getNextCredentialDID`; replaced `isInitialized()` with `getStandardIssuerDid() != null`; replaced `getPublicKey()` with `getKeyInformation()`
- Replaced `DidcommEncryptedMessage.fromPlaintext()` with `message.encrypt(wallet:, keyId:, recipientPublicKeyJwk:)`
- Updated `decrypt()` to use named `wallet:` parameter
- Fixed SD-JWT: replaced `SdJws.unverified()` with `toSdJwt()`, updated `bind()` to use `WalletCryptoProvider`
- Added `WalletKeyAgreementGenerator` for `ecdhES` call in `presentation_request.dart`
- Used `WalletSignatureGenerator.forDid()` for ISO mDOC device signing in `mdoc_provider.dart`
- Generated ephemeral `CoseKey.generate(CoseCurve.p256)` directly for BLE session in `mdoc_provider.dart` (avoids needing private key extraction)
- Rewrote `backup_functions.dart` to use `WalletStore.export()`/`import()` (removed `getBoxes()` dependency)
- Added `dart_ssi_compat.dart` import to all files using compat functions

**Files Modified:**
- `lib/functions/dart_ssi_compat.dart` (created)
- `lib/functions/backup_functions.dart` (rewritten)
- `lib/functions/didcomm_message_handler.dart`
- `lib/functions/issue_credential.dart`
- `lib/functions/present_proof.dart`
- `lib/functions/oidc_handler.dart`
- `lib/functions/util.dart`
- `lib/provider/wallet_provider.dart`
- `lib/provider/mdoc_provider.dart`
- `lib/provider/ausweis_provider.dart`
- `lib/views/presentation_request.dart`
- `lib/views/self_issuance.dart`
- `lib/views/web_view.dart`
- `lib/views/credential_detail.dart`
- `lib/views/credential_page.dart`
- `lib/views/payment_card_overview.dart`
- `lib/basicUi/standard/issuer_info.dart`
- `lib/basicUi/standard/requester_info.dart`
- `lib/basicUi/standard/id_card.dart`
- `pubspec.yaml` (dependency_overrides for pointycastle ^4.0.0)

## Previous Sessions

*Sessions before dart_ssi migration not recorded* 