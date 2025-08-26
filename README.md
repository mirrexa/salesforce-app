# Mirrexa - Salesforce App

## Overview

Mirrexa is a Salesforce Lightning Web Component (LWC) application that enables wealth managers to generate professional client documents directly within Salesforce. The app integrates with the Mirrexa platform to provide seamless document generation capabilities.

## Installation

### Prerequisites

- Salesforce org with Lightning Experience enabled.
- System Administrator access.
- API access enabled in your Salesforce org.

### Installation Steps

1. **Install the Package from AppExchange**
   - Install the app from the AppExchange.

2. **(Alternative) Install the Package from Source**
   - Clone this repository.
   - Install the package using the Salesforce CLI.
   - You may need to alter `package.json` to match your Salesforce org.
   - Run `npm run sf-deploy` to deploy the package to your Salesforce org.

3. **Follow the Installation Guide**
   - Follow the [Installation Guide](install-guide.md) for detailed instructions on how to install and configure the app.

## Technical Details

### Components Included

- **Lightning Web Components**: `generateMirrexaDocument`
- **Apex Classes**: `MirrexaSetupController`, OAuth and API integration classes
- **Permission Sets**: `Mirrexa_App_Access_2GP`
- **Connected Apps**: OAuth configuration for Mirrexa platform
- **External Credentials**: `MirrexaOAuth` for secure API authentication
- **Named Credentials**: `Mirrexa_API` for API endpoint configuration

### API Integration

The app integrates with the Mirrexa platform API at `https://api.mirrexa.ai` using OAuth 2.0 authentication.

### Security

- OAuth 2.0 authentication with Mirrexa platform
- Permission-based access control
- Secure API communication via Named Credentials
- No sensitive data stored in Salesforce

## Support

### Documentation

- [Installation Guide](install-guide.md)
- [Administrator Guide](admin-guide.md)
- [User Guide](user-guide.md)
- [Security Review](security-review.md)

### Getting Help

- **Email**: team@mirrexa.ai
- **Documentation**: [TODO: Add documentation URL]
- **Support Portal**: [TODO: Add support portal URL]

### Troubleshooting

#### Common Issues

1. **Authentication Fails**
   - Verify Remote Site Settings are configured
   - Check that OAuth credentials are valid
   - Ensure user has proper permissions

2. **Component Not Visible**
   - Verify user has "Mirrexa_App_Access_2GP" permission set
   - Check Lightning App Builder page configuration

3. **API Errors**
   - Verify Named Credential configuration
   - Check External Credential setup
   - Review Salesforce debug logs

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.
