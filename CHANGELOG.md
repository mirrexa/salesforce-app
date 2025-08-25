# Changelog

All notable changes to the Mirrexa Salesforce AppExchange app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial AppExchange package preparation
- Comprehensive documentation suite

## [1.0.0] - 2025-01-17

### Added
- Initial release of Mirrexa for Salesforce AppExchange
- OAuth 2.0 authentication with Mirrexa platform
- Lightning Web Component for document generation
- Apex controller for setup and configuration
- Permission set for controlled access
- External Credential and Named Credential configuration
- Connected App for OAuth integration
- Remote Site Settings for API communication

### Features
- **Authentication Flow**: Secure OAuth connection with Mirrexa platform
- **Document Generation**: Generate professional client documents from Salesforce
- **Permission-Based Access**: Controlled access through Salesforce permission sets
- **Automated Setup**: Programmatic configuration of OAuth components
- **Error Handling**: Comprehensive error handling and user feedback

### Technical Components
- Lightning Web Component: `generateMirrexaDocument`
- Apex Classes:
  - `MirrexaSetupController` - Main setup and configuration controller
  - [TODO: List other Apex classes]
- Permission Set: `Mirrexa_App_Access_2GP`
- Connected App: OAuth configuration
- External Credential: `MirrexaOAuth`
- Named Credential: `Mirrexa_API`
- Remote Site Settings for API endpoints

### Security
- OAuth 2.0 authentication flow
- Secure API communication via Named Credentials
- Permission-based access control
- No sensitive data storage in Salesforce

---

## Version Format

- **Major** version when you make incompatible API changes
- **Minor** version when you add functionality in a backwards compatible manner
- **Patch** version when you make backwards compatible bug fixes

## Categories

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** in case of vulnerabilities
