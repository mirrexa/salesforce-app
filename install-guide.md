# Mirrexa - Installation Guide

## Overview

This guide provides detailed instructions for installing and configuring the Mirrexa Salesforce AppExchange app in your Salesforce organization.

## Prerequisites

Before installing Mirrexa, ensure your Salesforce org meets the following requirements:

### System Requirements
- **Salesforce Edition**: Professional, Enterprise, Performance, or Developer Edition
- **Lightning Experience**: Must be enabled (Classic not supported)
- **API Access**: Enabled in your Salesforce org
- **User Permissions**: System Administrator access for installation

### Browser Requirements
- Chrome 90+, Firefox 88+, Safari 14+, or Edge 90+
- JavaScript enabled
- Pop-up blockers disabled for your Salesforce domain

## Installation Process

### Step 1: Install from AppExchange

1. **Access AppExchange**
   - Log into your Salesforce org as a System Administrator
   - Navigate to the AppExchange (https://appexchange.salesforce.com)
   - Search for "Mirrexa"

2. **Install the Package**
   - Click "Get It Now" on the Mirrexa listing
   - Select your target org (Production or Sandbox)
   - Choose installation option:
     - **Install for All Users** (Recommended)
     - **Install for Admins Only**
     - **Install for Specific Profiles**

3. **Review Package Contents**
   - Review the components that will be installed
   - Accept the terms and conditions
   - Click "Install"

4. **Monitor Installation**
   - Installation typically takes 5-10 minutes
   - You'll receive an email notification when complete
   - Check Setup → Installed Packages to verify installation

### Step 2: Post-Installation Configuration

#### 2.1 Verify Remote Site Settings

1. Navigate to **Setup → Security → Remote Site Settings**
2. Verify the following remote sites are created:
   - **Mirrexa_Auth_API**: `https://api.mirrexa.ai`
   - **Mirrexa_Web**: `https://mirrexa.ai`

If missing, create them manually:
- Name: `Mirrexa_Auth_API`
- Remote Site URL: `https://api.mirrexa.ai`
- Active: ✓ Checked

#### 2.2 Configure External Credentials

1. Navigate to **Setup → Security → Named Credentials**
2. Verify "Mirrexa_API" Named Credential exists
3. Check that External Credential "MirrexaOAuth" is properly configured

#### 2.3 Assign Permission Sets

1. Navigate to **Setup → Users → Permission Sets**
2. Find "Mirrexa_App_Access_2GP" permission set
3. Assign to users who need access to the app:
   - Click "Manage Assignments"
   - Click "Add Assignments"
   - Select users and click "Assign"

### Step 3: Add Component to Lightning Pages

#### Option A: Add to Record Pages

1. Navigate to **Setup → Object Manager**
2. Select the object where you want to add the component (e.g., Account, Contact)
3. Go to **Lightning Record Pages**
4. Edit an existing page or create a new one
5. Drag "Generate Mirrexa Document" component to the page
6. Save and activate the page

#### Option B: Add to App Pages

1. Navigate to **Setup → Lightning App Builder**
2. Create a new App Page or edit existing one
3. Drag "Generate Mirrexa Document" component to the page
4. Configure component properties if needed
5. Save and activate the page

#### Option C: Create Custom Tab

1. Navigate to **Setup → Tabs**
2. Click "New" in the Lightning Component Tabs section
3. Select "generateMirrexaDocument" as the Lightning Component
4. Configure tab properties:
   - Tab Label: "Mirrexa"
   - Tab Name: "Mirrexa"
   - Choose an appropriate icon
5. Set visibility for profiles
6. Add to relevant apps

### Step 4: Initial Setup and Testing

#### 4.1 Run Setup Controller (If Needed)

If OAuth components need manual configuration:

1. Open Developer Console
2. Execute Anonymous Apex:
```apex
MirrexaSetupController controller = new MirrexaSetupController();
controller.configureConnection();
```

#### 4.2 Test Authentication

1. Navigate to the Mirrexa component
2. Click "Authenticate with Mirrexa"
3. Complete OAuth flow in popup window
4. Verify successful authentication

#### 4.3 Test Document Generation

1. [TODO: Add specific test steps for document generation]
2. Verify component loads without errors
3. Test basic functionality
4. Check debug logs for any issues

## Troubleshooting

### Common Installation Issues

#### Issue: Package Installation Fails
**Symptoms**: Installation hangs or fails with error
**Solutions**:
- Retry installation after 30 minutes
- Check org limits (storage, API limits)
- Ensure no conflicting packages
- Contact Salesforce support if persistent

#### Issue: Components Not Visible
**Symptoms**: Users can't see the Mirrexa component
**Solutions**:
- Verify permission set assignment
- Check Lightning page configuration
- Ensure Lightning Experience is enabled
- Review profile permissions

#### Issue: OAuth Authentication Fails
**Symptoms**: Authentication popup fails or shows errors
**Solutions**:
- Verify Remote Site Settings
- Check External Credential configuration
- Ensure Named Credential is active
- Review Connected App settings

### Getting Help

If you encounter issues during installation:

1. **Check Debug Logs**
   - Setup → Environments → Logs → Debug Logs
   - Look for errors related to Mirrexa components

2. **Review Installation Status**
   - Setup → Installed Packages
   - Check package status and version

3. **Contact Support**
   - Email: team@mirrexa.ai
   - Include org ID, error messages, and debug logs

## Post-Installation Checklist

- [ ] Package successfully installed
- [ ] Remote Site Settings configured
- [ ] Permission sets assigned to users
- [ ] Component added to Lightning pages
- [ ] OAuth authentication tested
- [ ] Document generation tested
- [ ] Users trained on basic functionality

## Next Steps

After successful installation:

1. Review the [Administrator Guide](admin-guide.md) for ongoing management
2. Share the [User Guide](user-guide.md) with end users
3. Configure any additional settings as needed
4. Monitor usage and performance

---

**Need Help?** Contact our support team at [TODO: Add support contact information]
