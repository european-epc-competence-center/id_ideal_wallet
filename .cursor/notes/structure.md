# ID Ideal Wallet - Codebase Structure & Overview

## Project Overview

**ID Ideal Wallet** (also known as EECC Wallet, Hidy Wallet) is a Flutter-based digital identity wallet application that supports W3C Verifiable Credentials, DIDComm protocols, OpenID Connect for Verifiable Credential Issuance, and includes a custodial Lightning wallet for payments.

- **Current Version**: 1.0.2-test+5
- **Platform Support**: iOS (13.0+), Android 
- **Primary Use**: Digital identity management, credential storage, Lightning payments
- **Status**: Development/Testing (not recommended for production)

## Core Architecture

### Main Technologies & Dependencies
- **Framework**: Flutter 3.24.0+ with Dart 3.0+
- **State Management**: Provider pattern with ChangeNotifier
- **Local Storage**: Hive (via dart_ssi), Flutter Secure Storage, SharedPreferences
- **Encryption**: Local biometric auth, custom encryption providers
- **Key Libs**: dart_ssi, sd_jwt, iso_mdoc, mobile_scanner, qr_flutter, printing

### App Structure Overview

```
lib/
├── main.dart                 # App entry point, MultiProvider setup
├── constants/               # Configuration & static values
├── provider/               # State management (Provider pattern)
├── views/                  # Screen/page implementations  
├── basicUi/               # Reusable UI components
├── functions/             # Core business logic & utilities
└── l10n/                  # Internationalization (EN/DE)
```

## Core Providers (State Management)

### 1. WalletProvider (`lib/provider/wallet_provider.dart`)
**Primary wallet state and functionality**
- Manages VerifiableCredentials, ISO mDoc, SD-JWT credentials
- Lightning wallet integration (balance, payments, invoices)
- Credential issuance, presentation, and revocation checking
- Backup/restore functionality with mnemonic phrases
- ABO (subscription) management for wallet context
- PKPass file handling for Apple Wallet integration

### 2. NavigationProvider (`lib/provider/navigation_provider.dart`) 
**App navigation and routing**
- Page stack management with back navigation
- Deep link handling for various protocols
- Welcome screen flow control
- Navigation between 16 main pages (see NavigationPage enum)

### 3. MdocProvider (`lib/provider/mdoc_provider.dart`)
**ISO 18013-5 mDoc (mobile document) handling**
- NFC communication for document sharing
- BLE (Bluetooth Low Energy) document transmission  
- Device engagement and session management
- COSE key handling and encryption

### 4. AusweisProvider (`lib/provider/ausweis_provider.dart`)
**German ID card (Personalausweis) integration**
- Integration with AusweisApp2 SDK
- PIN/CAN/PUK entry flows
- Card reading and data extraction
- Authentication workflow management

### 5. EncryptionProvider (`lib/provider/encryption_provider.dart`)
**Data encryption and security**
- Mnemonic-based encryption
- Backup data encryption/decryption
- Password generation from mnemonics

## Main Views/Screens

### Navigation Pages (16 core screens)
1. **ABO** - Subscription/context overview
2. **Credential** - Main wallet credential view
3. **QR Scanner** - QR code scanning for various protocols
4. **Payment Card** - Lightning wallet payment methods
5. **Settings** - App configuration
6. **Web View** - In-app browser
7. **Credential Detail** - Individual credential details
8. **Authorized Apps** - OAuth/app permissions
9. **License** - Open source licenses
10. **Search New ABO** - Find new subscription contexts
11. **Send Satoshi** - Lightning payment sending
12. **Top Up** - Add funds to Lightning wallet
13. **Payment Overview** - Payment history/details
14. **Ausweis Start** - German ID card entry point
15. **Ausweis** - ID card reading interface
16. **ABO Detail** - Subscription detail view

### Key View Implementations
- **StartScreen**: Router between WelcomeScreen and HomeScreen
- **WelcomeScreen**: Onboarding, terms acceptance, backup setup
- **HomeScreen**: Main tabbed interface with floating action button
- **QrScanner**: Universal QR code handler for multiple protocols
- **CredentialPage**: Credential list with filtering (all/payment/identity)
- **PresentationRequest**: W3C VP (Verifiable Presentation) flow
- **CredentialOffer**: W3C VC (Verifiable Credential) issuance flow

## Core Functions & Utilities

### 1. Authentication & Security (`lib/functions/util.dart`)
- Biometric authentication (Face ID, Touch ID, fingerprint)
- Device capability checking
- Onboarding status management
- Certificate validation
- QR code parsing for various protocols

### 2. Payment Integration (`lib/functions/payment_utils.dart`)
- Lightning Network wallet management
- Invoice creation, decoding, payment
- LNURL handling (Lightning URL protocol)
- Payment method selection and processing
- Balance management and transaction history

### 3. OpenID Connect Handler (`lib/functions/oidc_handler.dart`)
- OID4VCI (OpenID for Verifiable Credential Issuance)
- OID4VP (OpenID for Verifiable Presentations)  
- OAuth flow management
- JWT/SD-JWT credential processing
- ISO mDoc credential handling via OpenID

### 4. DIDComm Integration (`lib/functions/didcomm_message_handler.dart`)
- DIDComm v1/v2 message processing
- Encrypted/signed message handling
- Out-of-band message processing
- Credential offer/request flows
- Presentation request handling

### 5. Backup Functions (`lib/functions/backup_functions.dart`)
- Mnemonic-based wallet backup
- Cloud backup upload/download
- Wallet restoration from backup
- Data encryption for backups

### 6. ID Card Integration (`lib/functions/ausweis_message.dart`)
- AusweisApp2 SDK message parsing
- German ID card workflow management
- Authentication state handling

## Platform-Specific Implementations

### Android (`android/`)
- **MainActivity.kt**: Platform channel implementations
- **HceService.kt**: NFC Host Card Emulation service
- Deep link handling for various protocols
- AusweisApp2 SDK integration
- NFC reader implementation
- Permissions: NFC, Camera, Biometric, Internet

### iOS (`ios/`)
- **AppDelegate.swift**: iOS-specific platform channels
- **CallbackManager.swift**: AusweisApp2 SDK callbacks
- **EventChannelManager.swift**: Flutter event streaming
- NFC capability integration
- App Store association file for deep links
- iOS 13.0+ deployment target

## Supported Protocols & Standards

### Identity Standards
- **W3C Verifiable Credentials (VCs)**: JSON-LD, JWT formats
- **W3C Verifiable Presentations (VPs)**: Presentation requests/responses
- **DIDComm v1/v2**: Encrypted messaging for credential exchange
- **ISO 18013-5**: Mobile driving license (mDoc) standard
- **SD-JWT**: Selective Disclosure JSON Web Tokens
- **OpenID Connect**: OID4VCI, OID4VP protocols

### Payment Standards  
- **Lightning Network**: Bitcoin Layer 2 payments
- **LNURL**: Lightning URL protocol for payments
- **Bech32**: Bitcoin address encoding

### Communication
- **QR Codes**: Multiple protocol support
- **Deep Links**: Custom schemes and universal links
- **NFC**: ISO 14443 Type A/B for document sharing
- **BLE**: Bluetooth Low Energy for offline sharing

## Configuration & Environment

### Server Endpoints (`lib/constants/server_address.dart`)
- **Production**: hidy.app, wallet.eecc.de
- **Test Environment**: Available but commented out
- **Lightning**: payments.pixeldev.eu
- **Relay**: 167.235.195.132:8888 for DIDComm messaging

### Supported Deep Link Schemes
- `openid-credential-offer://`
- `openid-credential-request://` 
- `openid4vp://`
- `https://wallet.bccm.dev` (universal links)
- `eudi-openid4ci://authorize` (EU Digital Identity)

### App Link Features
- QR code scanning with protocol detection
- WebView integration with wallet ID injection
- Lightning invoice/LNURL handling
- Credential offer/presentation request processing

## Security Features

### Authentication
- Biometric authentication (required for wallet access)
- Local device encryption
- Secure storage for sensitive data
- Screenshot prevention (FLAG_SECURE on Android)

### Data Protection
- Flutter Secure Storage for keys
- Mnemonic-based backup encryption
- Certificate validation for issuers
- Revocation checking for credentials

### Privacy
- Local-first storage approach
- Optional cloud backup with encryption
- Minimal data sharing
- User consent for credential sharing

## Internationalization

- **Supported Languages**: English (EN), German (DE)
- **Location**: `lib/l10n/` with .arb files
- **Generation**: `flutter gen-l10n` command
- **Dynamic**: Uses device locale preferences

## Build & Development

### Prerequisites
- Flutter 3.24.0 - 3.27.0
- Dart SDK 3.0+
- iOS 13.0+ (for iOS builds)
- Android API level varies by features

### Key Commands
```bash
flutter pub get           # Install dependencies
flutter gen-l10n         # Generate translations
flutter run              # Development run
flutter build apk        # Android build
flutter build ios        # iOS build
```

### Platform Setup Notes
- **iOS**: Requires paid Apple Developer account for NFC
- **Android**: NFC permissions configured
- **AusweisApp2**: SDK integration for German ID cards
- **Lightning**: Custodial wallet integration

## Key External Dependencies

### Identity & Crypto
- `dart_ssi`: W3C standards, DIDComm, wallet functionality
- `sd_jwt`: Selective Disclosure JWT implementation  
- `iso_mdoc`: ISO 18013-5 mobile document support
- `x509b`: X.509 certificate handling
- `crypto_keys`: Cryptographic key management

### UI & UX
- `mobile_scanner`: QR code scanning
- `qr_flutter`: QR code generation
- `local_auth`: Biometric authentication
- `printing`: PDF generation for receipts

### Platform Integration
- `flutter_secure_storage`: Secure local storage
- `shared_preferences`: App preferences
- `path_provider`: File system access
- `url_launcher`: External URL handling

## Development Status

- **Target Audience**: Testing, demonstration, research
- **Security**: Requires enrolled device authentication
- **Features**: Comprehensive but under active development
- **Standards Compliance**: Implements latest W3C and ISO standards
- **Lightning Integration**: Custodial wallet for Bitcoin payments

This codebase represents a comprehensive digital identity wallet implementing cutting-edge standards for verifiable credentials, mobile documents, and cryptocurrency payments, with strong security and privacy considerations. 