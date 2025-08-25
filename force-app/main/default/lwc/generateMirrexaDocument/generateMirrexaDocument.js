import generateAndAttachDocument from "@salesforce/apex/MirrexaApiService.generateAndAttachDocument";
import getDocumentTemplates from "@salesforce/apex/MirrexaApiService.getDocumentTemplates";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { LightningElement, api } from "lwc";

export default class GenerateMirrexaDocument extends NavigationMixin(
  LightningElement
) {
  // @api recordId is automatically populated by Salesforce
  // when the LWC is placed on a record page. This is the magic!
  @api recordId;

  isLoading = false;
  isWorking = false;
  canCheck = false;
  error;

  // Connection status - managed by child component
  connectionStatus = {
    isConnected: false,
    isNotAllowed: false,
    isLoading: false
  };

  // Template management
  templates = [];
  selectedTemplateId = undefined;
  templatesLoading = false;

  // Document configuration
  documentName = "";
  storeInMirrexa = false;

  // Progress tracking
  isConnected = false;

  connectedCallback() {
    this.storeInMirrexa = true;
  }

  async loadTemplates() {
    try {
      this.templatesLoading = true;
      const response = await getDocumentTemplates({
        page: 0,
        limit: 200,
        noLimit: true
      });
      const data = JSON.parse(response);

      if (data.success && data.message && data.message.data) {
        this.templates = data.message.data.map((template) => ({
          label: template.name,
          value: template.id,
          description: template.description
        }));

        // Auto-select the first template if available
        if (this.templates.length > 0) {
          this.selectedTemplateId = this.templates[0].value;
        }
      }
    } catch (error) {
      this.showToast(
        "Error Loading Templates",
        this.getErrorMessage(error),
        "error"
      );
    } finally {
      this.templatesLoading = false;
    }
  }

  handleTemplateChange(event) {
    this.selectedTemplateId = event.detail.value;
  }

  handleDocumentNameChange(event) {
    this.documentName = event.detail.value;
  }

  handleStoreInMirrexaChange(event) {
    this.storeInMirrexa = event.detail.checked;
  }

  async handleGenerateClick() {
    if (!this.recordId) {
      this.showToast("Error", "Record ID not found.", "error");
      return;
    }

    if (!this.selectedTemplateId) {
      this.showToast("Error", "Please select a template.", "error");
      return;
    }

    if (!this.documentName) {
      this.showToast("Error", "Please enter a document name.", "error");
      return;
    }

    this.isWorking = true;
    this.error = undefined;

    try {
      // Call the Apex method from our service class - now returns extraction key
      const state = await generateAndAttachDocument({
        recordId: this.recordId,
        templateId: this.selectedTemplateId,
        documentName: this.documentName,
        storeInMirrexa: this.storeInMirrexa
      });

      this.isWorking = false;

      // Reset the document name field
      this.documentName = "";

      if (state === "generated_and_attached") {
        this.showToast(
          "Success",
          "Document successfully generated and attached!",
          "success"
        );
        // Refresh the record view to show the newly attached file
        this.updateRecordView();
      } else if (state === "generated") {
        this.showToast(
          "Success",
          "Document successfully generated!",
          "success"
        );
      } else {
        this.showToast(
          "Error Generating Document",
          "Document generation failed.",
          "error"
        );
      }
    } catch (error) {
      this.error = error;
      this.isWorking = false;
      this.showToast(
        "Error Generating Document",
        this.getErrorMessage(error),
        "error"
      );
    }
  }

  disconnectedCallback() {}

  async refreshConnectionStatus() {
    // Delegate to the connection status component
    const connectionComponent = this.template.querySelector(
      "c-mirrexa-connection-status"
    );
    if (connectionComponent) {
      await connectionComponent.refreshConnectionStatus();
    }
  }

  // Event handlers for connection status component
  handleConnectionStatusChange(event) {
    const { isConnected, isNotAllowed, statusChanged, canCheck } = event.detail;
    this.isConnected = isConnected;
    this.canCheck = canCheck;
    this.connectionStatus.isConnected = isConnected;
    this.connectionStatus.isNotAllowed = isNotAllowed;

    if (statusChanged && isConnected) {
      // Load templates when connection is established
      this.loadTemplates();
      this.isLoading = false;
    }
  }

  handleConnectionError(event) {
    const { error } = event.detail;
    console.error("Connection Error", this.getErrorMessage(error));
    this.isLoading = false;
  }

  handleUserRegistered() {
    this.isLoading = false;
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  // Helper to refresh the record page data
  updateRecordView() {
    // Use a timeout to allow the server to process the attachment
    // before we request a refresh of the page.
    setTimeout(() => {
      try {
        // Try the modern approach first
        if (window.location && window.location.reload) {
          window.location.reload();
        } else {
          // Fallback to Aura method
          eval("$A.get('e.force:refreshView').fire();");
        }
      } catch (error) {
        console.error("Error refreshing page:", error);
        // Final fallback - just refresh the browser
        window.location.reload();
      }
    }, 1000);
  }

  // Navigate to Templates tab
  handleNavigateToTemplates() {
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "Templates"
      }
    });
  }

  // Helper to parse Salesforce Apex error messages
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

  get isNotAllowed() {
    return this.connectionStatus.isNotAllowed;
  }

  get connectionIsLoading() {
    return this.connectionStatus.isLoading;
  }
}
