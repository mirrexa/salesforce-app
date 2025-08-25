# Mirrexa - Salesforce AppExchange App

## Overview

Mirrexa is a Salesforce Lightning Web Component (LWC) application that enables wealth managers to generate professional client documents directly within Salesforce. The app integrates with the Mirrexa platform to provide seamless document generation capabilities.

## Features

- **OAuth Authentication**: Secure authentication with Mirrexa platform
- **Document Generation**: Generate professional client documents from Salesforce data
- **Lightning Web Components**: Modern, responsive UI built with Salesforce Lightning Design System
- **Permission-Based Access**: Controlled access through Salesforce permission sets

## Installation

### Prerequisites

- Salesforce org with Lightning Experience enabled
- System Administrator access
- API access enabled in your Salesforce org

### Installation Steps

1. **Install the Package**
   - Navigate to the AppExchange listing for Mirrexa
   - Click "Get It Now" and follow the installation wizard
   - Choose to install for "All Users" or specific profiles as needed

2. **Assign Permission Sets**
   - Go to Setup → Users → Permission Sets
   - Find "Mirrexa_App_Access_2GP" permission set
   - Assign it to users who need access to the app

3. **Configure OAuth Connection**
   - Navigate to the Mirrexa component in your Salesforce org
   - Click "Authenticate with Mirrexa" to establish OAuth connection
   - Complete the authentication flow in the popup window

4. **Verify Installation**
   - Test document generation functionality
   - Ensure all users can access the component as expected

## Usage

### For End Users

1. **Authentication**
   - Open the Mirrexa component
   - If not authenticated, click "Authenticate with Mirrexa"
   - Complete the OAuth flow in the popup window

2. **Generate Documents**
   - [TODO: Add specific usage instructions for document generation]
   - Select the appropriate document type
   - Configure document parameters
   - Generate and download the document

### For Administrators

1. **User Management**
   - Assign the "Mirrexa_App_Access_2GP" permission set to appropriate users
   - Monitor OAuth connections and authentication status

2. **Configuration**
   - [TODO: Add configuration options and settings]
   - Review Remote Site Settings if needed
   - Monitor app usage and performance

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
