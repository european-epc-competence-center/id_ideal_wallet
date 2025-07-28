# Notes Index - ID Ideal Wallet

## Quick Project Overview

**ID Ideal Wallet** is a Flutter-based digital identity wallet supporting W3C Verifiable Credentials, DIDComm protocols, OpenID Connect for VC Issuance, and custodial Lightning payments.

- **Version**: 1.0.2-test+5
- **Platforms**: iOS (13.0+), Android
- **Main Tech**: Flutter 3.24.0+, Provider state management, dart_ssi
- **Status**: Development/Testing phase

## Project Structure Summary

```
lib/
├── main.dart              # App entry point with MultiProvider setup
├── constants/            # Configuration values, server addresses, colors
├── provider/            # State management (5 main providers)
├── views/              # 20+ screen implementations
├── basicUi/            # Reusable UI components (standard & ausweis)
├── functions/          # Core business logic & utilities
└── l10n/              # Internationalization (EN/DE)
```

**Key Directories:**
- `android/` & `ios/` - Platform-specific code and configurations
- `assets/` - Fonts (Outfit, Urbanist), icons, images
- `doc/` - Technical documentation (flows, implementation notes, OID4VCI)

## Notes Files

### Core Documentation
- **[structure.md](mdc:.cursor/notes/structure.md)** - Comprehensive codebase structure, architecture overview, provider details, and main components breakdown

### Development Memory
- **[ai-notes.md](mdc:.cursor/notes/ai-notes.md)** - Persistent AI memory for tracking progress, decisions, and next steps across sessions

## Key Development Areas

- **State Management**: 5 main providers (WalletProvider, NavigationProvider, etc.)
- **Credential Management**: VC, ISO mDoc, SD-JWT support
- **Payment Integration**: Lightning wallet functionality
- **Security**: Biometric auth, encryption providers
- **UI Components**: Standardized themes with Outfit/Urbanist fonts
- **Internationalization**: German/English support 