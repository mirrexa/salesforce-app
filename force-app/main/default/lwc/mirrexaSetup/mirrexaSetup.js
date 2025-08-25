import configureConnection from "@salesforce/apex/MirrexaSetupController.configureConnection";
import getLastSetupResult from "@salesforce/apex/MirrexaSetupController.getLastSetupResult";
import { LightningElement, track } from "lwc";

// The origin of your callback page. CRITICAL for security.
const MIRREXA_AUTH_ORIGIN = "https://mirrexa.ai";

export default class MirrexaSetup extends LightningElement {
  @track statusMessage = "";
  @track errorMessage = "";
  @track isNamedCredentialConnected = false;
  @track isUserCredentialConnected = false;
  @track setupResult = {};
  @track isSetupComplete = false;

  // A unique value to prevent Cross-Site Request Forgery (CSRF)
  state;
  popup;

  connectedCallback() {
    // Listen for messages from the popup window
    window.addEventListener("message", this.handleMessage.bind(this));

    (async () => {
      const setupResult = await getLastSetupResult();
      this.setupResult = setupResult || {};
      this.isSetupComplete = false;
      //this.setupResult.lastSuccess && this.setupResult.lastSuccess.length > 0;
    })().catch((e) => console.error(e));
  }

  disconnectedCallback() {
    // Clean up the listener when the component is destroyed
    window.removeEventListener("message", this.handleMessage);
  }

  handleConnectClick() {
    this.statusMessage = "Opening Mirrexa login...";
    this.errorMessage = "";

    // 1. Generate a unique 'state' for this transaction
    this.state = this.generateRandomString();

    const salesforceOrigin = window.location.origin;

    // 2. Construct the full URL for the popup
    const mirrexaRegisterUrl = `${MIRREXA_AUTH_ORIGIN}/oauth-client/register?state=${this.state}&origin=${encodeURIComponent(salesforceOrigin)}`;

    // 3. Open the popup
    const width = 600,
      height = 700;
    const left = screen.width / 2 - width / 2;
    const top = screen.height / 2 - height / 2;
    this.popup = window.open(
      mirrexaRegisterUrl,
      "mirrexaLogin",
      `toolbar=no, location=no, directories=no, status=no, menubar=no,
             scrollbars=no, resizable=no, copyhistory=no, width=${width},
             height=${height}, top=${top}, left=${left}`
    );
  }

  // Event handlers for child connection status component
  handleConnectionStatusChange(event) {
    const { isConnected } = event.detail;
    this.isUserCredentialConnected = isConnected;
    if (this.isUserCredentialConnected) {
      this.statusMessage = "Connected to Mirrexa";
      this.errorMessage = "";
    }
  }

  handleConnectionError(event) {
    const { error } = event.detail;
    this.errorMessage = `Connection error: ${this.getErrorMessage(error)}`;
  }

  handleUserRegistered() {
    // Provide a light confirmation message
    this.statusMessage = "User registration confirmed with Mirrexa";
  }

  async handleMessage(message) {
    // 4. SECURITY CHECK: Ensure the message is from our trusted domain
    if (message.origin !== MIRREXA_AUTH_ORIGIN) {
      console.error("Received message from untrusted origin:", message.origin);
      return;
    }

    const data = message.data;

    // 5. SECURITY CHECK: Verify the 'state' matches
    if (data.state !== this.state) {
      this.errorMessage =
        "Security validation failed (state mismatch). Please try again.";
      return;
    }

    // 6. Close the popup and process the data
    if (this.popup) {
      this.popup.close();
    }

    if (data.status === "success") {
      this.statusMessage =
        "Received credentials. Creating connection in Salesforce...";
      try {
        // 7. Call Apex to create the metadata
        const result = await configureConnection({
          clientId: data.clientId,
          clientSecret: data.clientSecret
        });

        if (result && result.success) {
          this.statusMessage =
            result.message || "Auth Provider successfully updated";
          this.isNamedCredentialConnected = true;
        } else {
          this.errorMessage =
            "Connection setup completed but returned an unexpected response";
          console.warn(
            "Unexpected response from server:",
            JSON.stringify(result)
          );
        }
      } catch (error) {
        console.error("Error creating connection:", error);
        const errorMsg = this.getErrorMessage(error);

        // Log the full error for debugging
        console.error("Full error details:", errorMsg);

        // Extract debug info if present
        let displayError = errorMsg;
        const debugInfoIndex = errorMsg.indexOf("\n\nDebug info:");
        if (debugInfoIndex > -1) {
          // For UI display, only show the main error message, not the debug info
          displayError = errorMsg.substring(0, debugInfoIndex);
          console.info("Debug info:", errorMsg.substring(debugInfoIndex + 14));
        }

        this.errorMessage = "Error creating connection: " + displayError;
        this.statusMessage = "";
      }
    } else {
      this.errorMessage = "Mirrexa authorization failed. Please try again.";
      this.statusMessage = "";
    }
  }

  // Allow parent containers or buttons to trigger a fresh status check
  async refreshConnectionStatus() {
    const connectionComponent = this.template.querySelector(
      "c-mirrexa-connection-status"
    );
    if (connectionComponent) {
      await connectionComponent.refreshConnectionStatus();
    }
  }

  // Helper function to generate a random string for 'state'
  generateRandomString() {
    return Math.random().toString(36).substring(2, 15);
  }

  // Helper function to parse Salesforce Apex error messages
  getErrorMessage(error) {
    if (error.body) {
      if (Array.isArray(error.body)) {
        return error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        return error.body.message;
      }
    }
    return error.message;
  }
}
