# Mirrexa - Installation Guide

## Overview

This guide provides detailed instructions for installing and configuring the Mirrexa Salesforce AppExchange app in your Salesforce organization.

## Prerequisites

You must install the Salesforce App, either via AppExchange or by deploying this code.

## Installation Process

### Step 1: Assign the "Mirrexa_App_Access_2GP" Permission Set

1. **Assign the Permission Set**
   - Log into your Salesforce org as a System Administrator
   - Navigate to the Permission Sets (Setup → Users → Permission Sets)
   - Find "Mirrexa_App_Access_2GP" permission set
   - Assign to users who need access to the app:
     - Click "Manage Assignments"
     - Click "Add Assignments"
     - Select users and click "Assign"

### Step 2: Setup the App

1. **Use the Mirrexa App**
   - Logged in as a System Administrator with the "Mirrexa_App_Access_2GP" permission set.
   - Navigate to the Mirrexa App (9 dots → Mirrexa).
   - Navigate to the "Admin" tab.
   - Click on the "Connect to Mirrexa using this first" button.
       - Follow the instructions to connect to the Mirrexa platform, you may need to create a Mirrexa account.
       - This step is needed to connect your Salesforce org to the Mirrexa platform, but it does not connect the user.
   - Wait a moment for the page to refresh, it will eventually say "Connection Successful".
   - Now press the "Connect to Mirrexa" button.
       - Follow the instructions to connect to the Mirrexa platform, you may need to create a Mirrexa account.
       - This step is needed to connect the user to the Mirrexa platform.
       - This is the same flow that your users will need to go through.

### Step 3: Add the Component to a Lightning Page

1. **Add the Component to a Lightning Page**
   - Navigate to the Lightning Page where you want to add the component (e.g., Account, Contact)
   - Go to **Lightning Record Pages**
   - Edit an existing page or create a new one
   - Drag "Generate Mirrexa Document" component to the page
   - Save and activate the page

## Next Steps

After successful installation:

1. Review the [Administrator Guide](admin-guide.md) for ongoing management
2. Share the [User Guide](user-guide.md) with end users
3. Configure any additional settings as needed
4. Monitor usage and performance

---

**Need Help?** Contact our support team at [TODO: Add support contact information]
