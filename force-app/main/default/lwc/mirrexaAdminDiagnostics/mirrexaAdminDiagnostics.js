import checkNamedCredentialExists from "@salesforce/apex/MirrexaAdminController.checkNamedCredentialExists";
import debugPermissionSetup from "@salesforce/apex/MirrexaSetupController.debugPermissionSetup";
import getLastSetupResult from "@salesforce/apex/MirrexaSetupController.getLastSetupResult";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, track } from "lwc";

export default class MirrexaAdminDiagnostics extends LightningElement {
  @track setupResult = {};
  @track permissionDebugInfo = "";
  @track namedCredentialExists = false;
  @track namedCredentialUrl = "";
  @track isLoading = true;
  @track hasSetupErrors = false;
  @track hasCompletedSteps = false;
  @track setupStatus = "";
  @track setupStatusVariant;

  connectedCallback() {
    this.loadDashboardData().catch((e) => console.error(e));
  }

  async loadDashboardData() {
    this.isLoading = true;
    try {
      // Load setup result
      const setupResult = await getLastSetupResult();
      this.setupResult = setupResult || {};
      this.hasSetupErrors =
        this.setupResult.lastError && this.setupResult.lastError.length > 0;
      this.hasCompletedSteps =
        this.setupResult.lastSuccess && this.setupResult.lastSuccess.length > 0;
      this.setupStatus = this.hasCompletedSteps
        ? "Setup completed successfully"
        : this.hasSetupErrors
          ? "Setup completed with errors"
          : "Setup not started";
      this.setupStatusVariant = this.hasCompletedSteps
        ? "success"
        : this.hasSetupErrors
          ? "error"
          : "warning";

      // Check named credential
      const credentialInfo = await checkNamedCredentialExists();
      this.namedCredentialExists = credentialInfo.exists;
      this.namedCredentialUrl = credentialInfo.url;
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to load dashboard data: " + error.body?.message,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  async handleDebugPermissions() {
    try {
      const debugInfo = await debugPermissionSetup();
      this.permissionDebugInfo = JSON.stringify(debugInfo, null, 2);
    } catch (error) {
      this.showToast(
        "Error",
        "Failed to debug permissions: " + error.body?.message,
        "error"
      );
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
